--[[
	Returns information about a given png
	
	WARNING: 
	 * This particular object only works for pngs with 8 bits per pixel
--]]
--// TYPES
local Map = require('./@CHL>Map')
local BufferWrapper = require('./@CHL>BufferWrapper')
local Deflate = require('./@davidm>deflate')
local Object = require('./Object')

type map<I, V> = Map.simple<I, V>
type buffer_w = BufferWrapper.object

export type pixel = {
	r: number;
	g: number;
	b: number;
	
	-- larger this gets, the more opaque it is
	t: number;
}

export type chunk = {
	length: number;
	chunk_type: string;
	data: string;
	crc: number;
};

export type object = {
	chunks: map<string, any>;
	stream: BufferWrapper.stream;
	thread: thread;
	
	next: (self: object)->number;
	get_chunk: (self: object) -> chunk;
	get_pixel_from_2D_position: (self: object, x: number, y: number) -> pixel?;
	get_2D_position: (self: object, p: number) -> (number, number);
	get_stream_position: (self: object, x: number, y: number) -> number;
	
	parse_upfront: (self: object)->();
}

--// MAIN
local LuaUTypes = require('./LuaUTypes')

PNG = {}
from = {}

disguise = LuaUTypes.disguise
PNG.__index = PNG
pixelsColors = ('rgb'):split('')
to_buffer_w = BufferWrapper.from.string
to_stream = BufferWrapper.Stream.new

function from.string(s: string)
	assert(type(s) == 'string')
	return PNG.new(to_buffer_w(s))
end

function PNG.new(buffer_w: buffer_w, delay: number?, chunks_before_wait: number?)
	-- main
	local self: object = Object.simple.new(PNG)
	local stream = to_stream(buffer_w);
	
	local delay_t = delay or 1/60

	self.stream = stream

	-- check
	assert(stream:readu8() == 0x89,              'PNG Header Fail 1')
	assert(stream:readstring(3) == 'PNG',        'PNG Header Fail 2')
	assert(stream:readu32(true) == 0x0D0A1A0A,   `PNG Header Fail 3`)
	
	-- get chunks
	--[[
		.IHDR
			Struct representing the png information
		.IDAT
			An 1D array representing the pixel sequence. It goes from left to right 
			then up and down
	--]]
	self.chunks = {
		IDAT = {
			raw_data = {};
			pixels = {};
			row_filter_types = {};
			chunk_dictionary_byte = {}
		};
		IHDR = {}
	};
	
	-- parse chunks
	local chunks = 0
	repeat
		local chunk = self:get_chunk()
		local data_stream = to_stream(to_buffer_w(chunk.data))
		
		if chunk.chunk_type == 'IHDR' then -- header
			local IHDR = self.chunks.IHDR
			IHDR.width = data_stream:readu32(true)
			IHDR.height = data_stream:readu32(true)
			IHDR.bits_per_pixel = data_stream:readu8();
			IHDR.color_type = data_stream:readu8()
			IHDR.compression_method = data_stream:readu8()
			IHDR.filter_method = data_stream:readu8()
			IHDR.interlace = data_stream:readu8()
			
			assert(
				IHDR.compression_method == 0, 
				`unsupported compression method: {IHDR.compression_method}`
			)
			assert(IHDR.interlace == 0, `unsupported interlace: {IHDR.interlace}`)
			assert(
				IHDR.filter_method == 0, 
				`unsupported filter method: {IHDR.filter_method}`
			)
		elseif chunk.chunk_type == 'IDAT' then -- data
			-- note how we store all of the IDAT compressed data before
			-- compiling instead of compiling per compressed data
			table.insert(
				self.chunks.IDAT.raw_data,
				chunk.data
			)
			
			-- check sum (ad something idk)
			data_stream:get_bytes(4)
		elseif chunk.chunk_type ~= 'IEND' then
			warn('no chunk:', chunk.chunk_type)
		end
		
		chunks += 1
		if chunks_before_wait and chunks % chunks_before_wait == 0 then
			wait(delay_t)
		end
		
	until chunk.chunk_type == 'IEND' -- end does nothing
	
	assert(self.chunks.IHDR)
	-- compile IDAT
	local row = 0
	
	-- parse IDAT data
	-- refer to https://youtu.be/EFUYNoFRHQI?t=877
	-- note how we use zlib instead of the default inflate as described in the library
	self.thread = coroutine.create(function()
		Deflate.inflate_zlib{
			input = function()
				row += 1

				return self.chunks.IDAT.raw_data[row]
			end,
			output = function(byte)
				coroutine.yield(byte)
			end,
		}
	end)
	
	--[=[
	-- RGB based color types
	if color_type == 2 or color_type == 6 and index then
		currentStruct[index] = byte

		if color_type == 2 and index == 'b' then
			index = nil
		end
	elseif color_type == 0 or color_type == 4 then -- greyscale color types
		error('to do')
	elseif index then
		error('invalid color type: ' .. color_type)
	end

	-- unselect current struct if we finished constructing the struct
	if not index then
		currentStruct = nil

		-- unselect filter type if we finished the row
		if xP == width then
			filterType = nil
		end
	end
	]=]
	
	
	

	return self
end

function PNG.parse_upfront(self: object)
	local ihdr = self.chunks.IHDR
	local height, width, color_type = ihdr.height, ihdr.weight, ihdr.color_type
	local pixels = self.chunks.IDAT.pixels
	
	for r = 1, height do
		local filter_type = self:next()

		table.insert(self.chunks.IDAT.row_filter_types, filter_type)

		for c = 1, width do

			-- get current pixel
			local pixel = {
				r = self:next();
				g = self:next();
				b = self:next();
			}

			if color_type == 6 then
				pixel.t = self:next()
			else
				-- consider colortype 3 which refers to a palette

				error('unhandled: ' .. color_type)
			end

			-- get other pixels
			local stream_p = #pixels + 1
			local x, y = self:get_2D_position(stream_p)
			local left_pixel = self:get_pixel_from_2D_position(c - 1, r)
			local up_pixel = self:get_pixel_from_2D_position(c, r - 1)
			local upper_left_pixel = self:get_pixel_from_2D_position(c - 1, r - 1)

			for i, v in pixel do
				-- apply filters
				local l, u, u_l = 
					left_pixel and left_pixel[i] or 0,
					up_pixel and up_pixel[i] or 0,
					upper_left_pixel and upper_left_pixel[i] or 0

				--[[
					note how most mathmatical operations under this section are 
					mod'd by 256 (currently supported) since bytes themselves cant expand beyond 8 bits 
					so we are only restricted to an integer 0-255
				--]]
				if filter_type == 0 then     -- none
				elseif filter_type == 1 then -- sub
					--[[change byte based on the sum of the prev byte and 
						the current byte, then mod by 256,
						note, if the byte is the first pixel of a row, 
						it does not get changed
					--]]
					v += l
				elseif filter_type == 2 then -- up
					--[[
						same as sub but above the pixel, the upper pixel can be
						obtained based on the IHDR's dimentional width
						
						OOOOO
						OOXOO
						OO+
					--]]
					v += u
				elseif filter_type == 3 then -- average (...)
					--[[
						combines both up and sub:
						averages upper and previous pixel then adds with the
						current byte
						
						Note how the decoding of a png ceils a number insteads of flooring it,
						since in the case of  the byte given may have a mantissa of .5, it 
						would mean that the mantissa was cut off during encoding
					--]]

					v += ((u + l) // 2)
				elseif filter_type == 4 then -- paeth (...)
					--[[
						take the prev (p), upper (u), and upper prev pixel (uP),
						
						1. let v = p + u - uP
						2. find the smallest difference of v with the other pixels
						3. increment byte based on the corresponding difference
					--]]

					local w = u + l - u_l
					--v %= 256

					local a = math.min(
						math.abs(w - u), 
						math.abs(w - l),
						math.abs(w - u_l)
					) 

					v += 
						if a == math.abs(w - u) 
						then u
						elseif a == math.abs(w - l) 
						then l
						else u_l
				end

				v %= 256

				pixel[i] = v
			end

			table.insert(pixels, pixel)
		end
	end

end

function PNG.next(self: object)
	local _, byte = coroutine.resume(self.thread)
	return byte
end

function PNG.get_chunk(self: object)
	local stream = self.stream
	local chunk = {}
	chunk.length = stream:readu32(true)
	chunk.chunk_type = stream:readstring(4)
	chunk.data = stream:readstring(chunk.length)
	chunk.crc = stream:readu32()

	return chunk
end

--[[
	note: one indexed based function
	   X
	  123
	 1
	y2
	 3
	
	IN: number: x
		number: y
	
	Out: struct: {
		r = red;
		g = green;
		b = blue
	}
--]]
function PNG.get_pixel_from_2D_position(self: object, x, y)
	-- main
	return 
		if x <= 0 or x > self.chunks.IHDR.width 
		or y <= 0 or y > self.chunks.IHDR.height then
			nil
		else self.chunks.IDAT.pixels[self:get_stream_position(x, y)]
end

function PNG.get_2D_position(self: object, p)
	-- pre
	assert(
		type(p) == 'number' 
			and p > 0 
			--and p <= #self.chunks.IDAT.pixels
			and p % 1 == 0
	)

	-- main
	local w = self.chunks.IHDR.width
	
	return (p - 1) % w + 1,
		((p - 1) // w) + 1
end

function PNG.get_stream_position(self: object, x, y)
	-- pre
	assert(
		type(x) == 'number' 
			and x % 1 == 0
			and type(y) == 'number'
			and y % 1 == 0
	)

	-- main
	return 
		x + 
		(y - 1) * self.chunks.IHDR.width
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

export type iterator = {
	referral: object;
	i: number;
	max: number;
	previous_row: {pixel};
	current_row: {pixel};
	current_data_row: number;
	thread: thread;
	current_row_filter: number;
	
	
	next_byte: (self: iterator)->number;
	proceed: (self: iterator)->pixel?;
	can_proceed: (self: iterator)->boolean;
}

Iterator = {}

function Iterator.new(ref: object): iterator
	local self: iterator = Object.simple.new(Iterator)
	local ihdr = ref.chunks.IHDR
	self.referral = ref
	self.i = 0
	self.max = ihdr.width * ihdr.height
	self.current_row = {}
	self.current_data_row = 0
	
	
	self.thread = coroutine.create(function()
		Deflate.inflate_zlib{
			input = function()
				self.current_data_row += 1

				return self.referral.chunks.IDAT.raw_data[self.current_data_row]
			end,
			output = function(byte)
				coroutine.yield(byte)
			end,
		}
	end)

	return self
end

function Iterator.can_proceed(self: iterator)
	return self.i < self.max
end

function Iterator.next_byte(self: iterator)
	local _, b = coroutine.resume(self.thread)
	return b
end

function Iterator.proceed(self: iterator)
	if not self:can_proceed() then return end
	
	if #self.current_row == 0 then
		self.current_row_filter = self:next_byte()
	end
	
	local ihdr = self.referral.chunks.IHDR
	local row_filter = self.current_row_filter
	local pixel = {
		r = self:next_byte();
		g = self:next_byte();
		b = self:next_byte()
	}
	
	if ihdr.color_type == 6 then
		pixel.t = self:next_byte()
	else
		error('incomplete')
	end

	self.i += 1
	
	local x = self.referral:get_2D_position(self.i)
	
	local left_pixel = self.current_row[x - 1]
	local up_pixel, upper_left_pixel
	
	if self.previous_row then
		up_pixel = self.previous_row[x]
		upper_left_pixel = self.previous_row[x - 1]
	end
	
	for i, v in pixel do
		-- apply filters
		local l, u, u_l = 
			left_pixel and left_pixel[i] or 0,
			up_pixel and up_pixel[i] or 0,
			upper_left_pixel and upper_left_pixel[i] or 0

				--[[
					note how most mathmatical operations under this section are 
					mod'd by 256 (currently supported) since bytes themselves cant expand beyond 8 bits 
					so we are only restricted to an integer 0-255
				--]]
		if row_filter == 0 then     -- none
		elseif row_filter == 1 then -- sub
					--[[change byte based on the sum of the prev byte and 
						the current byte, then mod by 256,
						note, if the byte is the first pixel of a row, 
						it does not get changed
					--]]
			v += l
		elseif row_filter == 2 then -- up
					--[[
						same as sub but above the pixel, the upper pixel can be
						obtained based on the IHDR's dimentional width
						
						OOOOO
						OOXOO
						OO+
					--]]
			v += u
		elseif row_filter == 3 then -- average (...)
					--[[
						combines both up and sub:
						averages upper and previous pixel then adds with the
						current byte
						
						Note how the decoding of a png ceils a number insteads of flooring it,
						since in the case of  the byte given may have a mantissa of .5, it 
						would mean that the mantissa was cut off during encoding
					--]]

			v += ((u + l) // 2)
		elseif row_filter == 4 then -- paeth (...)
					--[[
						take the prev (p), upper (u), and upper prev pixel (uP),
						
						1. let v = p + u - uP
						2. find the smallest difference of v with the other pixels
						3. increment byte based on the corresponding difference
					--]]

			local w = u + l - u_l
			--v %= 256

			local a = math.min(
				math.abs(w - u), 
				math.abs(w - l),
				math.abs(w - u_l)
			) 

			v += 
				if a == math.abs(w - u) 
				then u
				elseif a == math.abs(w - l) 
				then l
				else u_l
		end

		v %= 256

		pixel[i] = v
	end
	
	table.insert(self.current_row, pixel)
	
	if #self.current_row >= ihdr.width then
		local temp = self.previous_row
		self.previous_row = self.current_row
		self.current_row = temp or {}
		
		table.clear(self.current_row)
	end
	
	return pixel
end

Iterator.__index = Iterator

PNG.iterator = Iterator

return PNG
