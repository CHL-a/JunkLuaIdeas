--// TYPES
export type object = {
	referral: buffer;
	is_big_endian_default: boolean;
	
	__len: (self: object) -> number;
	len: (self: object) -> number;
	__tostring: (self: object) -> string;
	to_string: (self: object, sType: number?, ...any) -> string;
	-- swaps specific bytes at i and j, is_contiguous does the same for all bytes in between
	swap_bytes: (self: object, offsetI: number, offsetJ: number, is_contiguous: boolean?) -> ();
	
	get_bytes: (self: object, offset: number, len: number?) -> {number};
	read_float: (self: object, offset: number) -> number;
	read_double: (self: object, offset: number) -> number;
	readstring: (self: object, offset: number, len: number) -> string;
	readi8: (self: object, offset: number) -> number;
	readu8: (self: object, offset: number) -> number;
	readi16: (self: object, offset: number, is_big_endian: boolean?) -> number;
	readu16: (self: object, offset: number, is_big_endian: boolean?) -> number;
	readi32: (self: object, offset: number, is_big_endian: boolean?) -> number;
	readu32: (self: object, offset: number, is_big_endian: boolean?) -> number;
	readf32: (self: object, offset: number, is_big_endian: boolean?) -> number;
	readf64: (self: object, offset: number, is_big_endian: boolean?) -> number;
	readu64: (self: object, offset: number, is_big_endian: boolean?) -> number;

	write_bytes: (self: object, offset: number, ...number) -> ();
	write_float: (self: object, offset: number, val: number) -> ();
	write_double: (self: object, offset: number, val: number) -> ();
	writestring: (self: object, offset: number, val: string, count: number?) -> ();
	writei8: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writeu8: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writei16: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writeu16: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writei32: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writeu32: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writef32: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writef64: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	writeu64: (self: object, offset: number, val: number, is_big_endian: boolean?) -> ();
	
	copy: (self: object, fromOffset: number, to: buffer | object, toOffset: number?, 
		count: number?) -> ();
	fill: (self: object, offset: number, val: number, count: number?) -> ();
	realloc: (self: object, new_size: number)->();
}

--// MAIN
local LuaUTypes = require('./LuaUTypes')
local Dash = require('./@CHL>DashSingular')
local Radix = require('./@CHL>Radix')
local Iterator = require('./@CHL>Iterator')
local Class = require('./Class')
local StringUtils = require('./@CHL>StringUtils')
local Math = require('./@CHL>Math')
local Bit32Ext = require('./@CHL>Bit32Ext')

module = {}
from = {}
raw_constructors = {}
disguise = LuaUTypes.disguise
compose = Dash.compose
hexUpper = Radix.charRadix.hexdecUpper
readu8 = buffer.readu8
len = buffer.len
insert = table.insert
gdiv = Math.glass_div

--#####################################################################################
--#####################################################################################
--#####################################################################################
-- primarily on the buffer primatives

primative = {}

primative.from = {}

function primative.from.bytes(...: number): buffer
	local n = select('#', ...)
	local b = buffer.create(n)
	for i = 1, n do
		local byte = select(i, ...)
		buffer.writeu8(b, i - 1, byte)
	end

	return b
end

function primative.realloc(b: buffer, new_size: number)
	local result = buffer.create(new_size)
	local min = math.min(new_size, buffer.len(b))
	
	for i = 1, min do
		buffer.writeu8(result, i - 1, buffer.readu8(b, i - 1))
	end
	
	return result
end

module.primative = primative

--#####################################################################################
--#####################################################################################
--#####################################################################################

function from.string(s: string): object return module.new(buffer.fromstring(s))end
function from.size(n: number): object return module.new(buffer.create(n))end

function module.new(b: buffer): object
	local self: object = disguise(setmetatable({}, module))
	self.referral = b

	return self
end

function enque_referral(self: object, ...)return self.referral, ... end

function endian_applied(n_tuple: number, length: number, f: any)
	return function(self: object, offset: number, ...)
		local last_arg = select(n_tuple, ...)
		local is_big_endian = typeof(last_arg) == 'boolean' and last_arg or self.is_big_endian_default
		
		--print(last_arg, is_big_endian)
		--print(offset, length)
		if is_big_endian then
			self:swap_bytes(offset, offset + length - 1, true)
		end
		
		local result = f(self.referral, offset, ...)
		
		if is_big_endian then
			self:swap_bytes(offset, offset + length - 1, true)
		end
		
		return result
	end
end

function module.swap_bytes(self: object, i: number, j: number, is_contigous: boolean?)
	if is_contigous then
		-- contiguous switch
		local diff = j - i + 1
		local half = diff // 2
		local last = half - 1
		
		for k = 0, last do
			self:swap_bytes(i + k, j - k)
		end
	else
		-- single switch
		local t = self:readu8(i)
		self:writeu8(i, self:readu8(j))
		self:writeu8(j, t)
	end
end

function module.write_bytes(self: object, offset: number, ...: number)
	for i = 1, select('#', ...) do
		local b = select(i, ...)
		self:writeu8(offset + i - 1, b)
	end
end

function module.get_bytes(self: object, offset: number, len: number)
	len = len or 1

	local result = {}

	for i = 1, len do
		table.insert(result, self:readu8(offset + i - 1))
	end

	return result
end

function module.to_string(self: object, sType: number?, ...)
	if not sType then return buffer.tostring(self.referral) end
	
	local len = self:len()
	local arg1, arg2 = ...
	
	if sType == 1 then
		local bytes = self:get_bytes(0, len)

		for i = 1, len do
			bytes[i] = hexUpper:formatSequence(bytes[i], 2)
		end

		return table.concat(bytes, '_')
	elseif sType == 2 then
		--[[
		Sample:
		
		+--+----------------+
		|rw|0123456789ABCDEF|
		+--+----------------+
		|00|................|
		|10|................|
		|20|                |
		...
		]]
		local viewing_size = 0x100
		
		-- row_offset = arg1
		arg1 = arg1 or 0
		
		local row_len = gdiv(viewing_size, 0x10)
		local rw_len = math.max(2, #hexUpper:formatSequence(len))
		
		local strings = {}
		local line_1 = `+{('-'):rep(rw_len)}+----------------+`
		
		-- this part is responsible for the header, based on the sample above
		strings[1] = line_1 .. '\n'
		strings[2] = `|{(' '):rep(rw_len - 2)}rw|0123456789ABCDEF|\n`
		strings[3] = strings[1]
		
		print(row_len)
		
		-- this part inserts to the table by row, starting with the index then content
		for r = 1, row_len do
			r -= 1
			insert(strings, `|{hexUpper:formatSequence(r, rw_len-1)}0|`)
			
			for c = 1, 0x10 do
				c -= 1
				
				local char = ' '
				local i = viewing_size * arg1 + r * 0x10 + c
				
				if i < len then
					local byte = self:readu8(i)
					
					char = string.char(byte)

					if not StringUtils.char.is_printable(char) then
						char = '.'
					end
				end
				
				insert(strings, char)
			end
			
			insert(strings,'|\n')
		end
		
		insert(strings, line_1)
		
		return table.concat(strings)
	elseif sType== 3 or sType == 4 then
		-- arg1 == offset (0 based)
		-- arg2 == len (1 based, in terms of 0x100 blocks)
		-- row_offset = arg1
		--[[
		Sample:
		
		+--+-----------------------------------------------+
		|rw|00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F|
		+--+-----------------------------------------------+
		|00|xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx|
		|10|xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx|
		|20|xx xx xx xx xx xx xx xx xx xx xx xx xx xx      |
		...
		]]
		local viewing_size = (arg2 or 1) * 0x100
		
		if arg2 == 0 then
			viewing_size = 0x100 * math.max(1, gdiv(self:len(), 0x100))
		end
		
		local row_len = gdiv(viewing_size, 0x10)
		local rw_len = math.max(2, #hexUpper:formatSequence(len))
		local strs = {}
		local line_1 = `+{('-'):rep(rw_len)}+-----------------------------------------------+`
		
		strs[1] = line_1 .. '\n'
		strs[2] = `|{(' '):rep(rw_len - 2)}rw|00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F|\n`
		strs[3] = strs[1]
		
		-- explicit return because clamp will error
		if len == 0 then return table.concat(strs) end
		
		arg1 = math.clamp(arg1 or 0, 0, gdiv(len, 0x100) - 1)
		
		for r = 1, row_len do
			r -= 1
			insert(strs, `|{hexUpper:formatSequence(arg1 * (viewing_size / 0x10) + r,rw_len-1)}0|`)

			for c = 1, 0x10 do
				c -= 1

				local set = '  '
				local i = viewing_size * arg1 + r * 0x10 + c

				if i < len then
					local byte = self:readu8(i)
					local char = string.char(byte)
					
					if sType == 4 and StringUtils.char.is_printable(char) then
						set = ` {char}`
					else
						set = hexUpper:formatSequence(byte, 2)
					end
					
				end

				insert(strs, set)
				
				if c == 0x0F then
					insert(strs, '|\n')
				else
					insert(strs, ' ')
				end
			end
		end
		
		insert(strs, line_1)
		return table.concat(strs)
	else error(`Bad sType: {sType}`)end
end

function module.copy(self: object, fromOffset: number, to: buffer | object, 
	toOffset: number?, count: number?)
	if typeof(to) == 'buffer' then
		return buffer.copy(self.referral, fromOffset, to, toOffset, count)
	end

	return self:copy(fromOffset, to.referral, toOffset, count)
end

function module.realloc(self: object, new_size: number)
	self.referral = primative.realloc(self.referral, new_size)
end

-- primary_debugging
function module.debug_find_diff(op_1: object, op_2: object): (boolean, string?)
	local least = math.min(op_1:len(), op_2:len())
	local most = math.max(op_1:len(), op_2:len())
	if least == 0 and most ~= least then
		return false, `\n{op_1:to_string(4)}\n{op_2:to_string(4)}`
	end
	
	local i = 0
	
	while i < least do
		local i_th_byte_same = op_1:readu8(i) == op_2:readu8(i)
		
		if not i_th_byte_same then
			break
		end
		
		i+=1
	end
	if least == most and i == least then
		return true, 'operands are same'
	else
		local start_at = i // 0x100
		
		local result = `start_at={start_at}\n`
		
		-- for horiontal alignment
		--[[
		local s1, s2 = op_1:to_string(4,start_at):split('\n'), op_2:to_string(4,start_at):split('\n')
		
		for i = 1, #s2 do
			s1[i] ..= s2[i]
		end
		result ..= table.concat(s1, '\n')
		--]]
		
		-- default: vertical alignment
		result..= op_1:to_string(4, start_at) .. '\n'
		result..= op_2:to_string(4, start_at)
		
		
		return false, result
	end
end

function module.writeu64(self: object, offset: number, val: number, is_big_endian: boolean?)
	local high, low = Bit32Ext.from_u64(val)
	
	if is_big_endian then
		self:writeu32(offset, high, true)
		self:writeu32(offset + 4, low, true)
	else
		self:writeu32(offset, low)
		self:writeu32(offset + 4, high)
	end
end

function module.readu64(self: object, offset: number, is_big_endian: boolean?): number
	local high, low

	if is_big_endian then
		high = self:readu32(offset, true)
		low = self:readu32(offset + 4, true)
	else
		high = self:readu32(offset + 4)
		low = self:readu32(offset)
	end
	
	return high * Bit32Ext.u32_max_after + low
end

module.readi8 = compose(enque_referral, buffer.readi8)
module.readu8 = compose(enque_referral, readu8)
module.readi16 = endian_applied(1, 2, buffer.readi16)
module.readu16 = endian_applied(1, 2, buffer.readu16) 
module.readi32 = endian_applied(1, 4, buffer.readi32)
module.readu32 = endian_applied(1, 4, buffer.readu32)
module.readf32 = endian_applied(1, 4, buffer.readf32)
module.readf64 = endian_applied(1, 8, buffer.readf64)
module.writei8 = compose(enque_referral, buffer.writei8)
module.writeu8 = compose(enque_referral, buffer.writeu8)
module.writei16 = endian_applied(2, 2, buffer.writei16)
module.writeu16 = endian_applied(2, 2, buffer.writeu16)
module.writei32 = endian_applied(2, 4, buffer.writei32)
module.writeu32 = endian_applied(2, 4, buffer.writeu32)
module.writef32 = endian_applied(2, 4, buffer.writef32)
module.writef64 = endian_applied(2, 8, buffer.writef64)
module.readstring = compose(enque_referral, buffer.readstring)
module.writestring = compose(enque_referral, buffer.writestring)
module.fill = compose(enque_referral, buffer.fill)
module.len = compose(enque_referral, len)
module.__tostring = module.to_string
module.__len = module.len
module.read_float = module.readf32
module.write_float = module.writef32
module.read_double = module.readf64
module.write_double = module.writef64
module.from = from
module.raw_constructors = raw_constructors

Class.make_proper_class(module, '@CHL>BufferWrapper')

--#####################################################################################
--#####################################################################################
--#####################################################################################

Temp = {}

Temp.temp = nil

function Temp.new(): object return module.from.size(8) end

function getTemp(): object
	if not Temp.temp then
		Temp.temp = Temp.new()
	end

	return Temp.temp
end

module.getTemp = getTemp

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Object = require('./Object')

export type iterator = {
	referral: buffer;
	current: number;
} & Iterator.simple<number> -- byte within buffer

b_iterator = {}

function b_iterator.init_simple(b: buffer)
	return b_iterator.simple, b, -1
end

function b_iterator.simple(b: buffer, current: number)
	current += 1
	if current >= len(b)then return;end
	return current, readu8(b, current)
end

function b_iterator.new(_buffer: buffer, _current: number?): iterator
	local self: iterator = Object.simple.new(b_iterator)
	if not (typeof(_buffer) == 'buffer') then
		print(_buffer)
	end
	assert(typeof(_buffer) == 'buffer', 'not buffer: ' .. typeof(_buffer))
	self.referral = _buffer
	self.current = _current or 0
	
	return self
end

function b_iterator.can_proceed(self: iterator)
	return len(self.referral) > self.current
end

function b_iterator.proceed(self: iterator)
	if not self:can_proceed() then
		return
	end
	local byte = readu8(self.referral, self.current)
	self.current += 1
	return byte
end

Class.makeProperClass(b_iterator, '@CHL>BufferWrapper>Iterator')

b_iterator.__iter = Iterator.simple.__iter

module.iterator = b_iterator

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type stream = {
	referral: object;
	i: number;
	
	increment: (self: stream, i: number?)->();

	write_bytes: (self: stream, ...number) -> ();
	get_bytes: (self: stream,  len: number?) -> {number};
	read_float: (self: stream) -> number;
	write_float: (self: stream,  val: number) -> ();
	read_double: (self: stream) -> number;
	write_double: (self: stream,  val: number) -> ();

	__len: (self: stream) -> number;
	len: (self: stream) -> number;
	readi8: (self: stream) -> number;
	readu8: (self: stream) -> number;
	readi16: (self: stream, is_big_endian: boolean) -> number;
	readu16: (self: stream, is_big_endian: boolean) -> number;
	readi32: (self: stream, is_big_endian: boolean) -> number;
	readu32: (self: stream, is_big_endian: boolean) -> number;
	readf32: (self: stream, is_big_endian: boolean) -> number;
	readf64: (self: stream, is_big_endian: boolean) -> number;
	writei8: (self: stream,  val: number) -> ();
	writeu8: (self: stream,  val: number) -> ();
	writei16: (self: stream,  val: number, is_big_endian: boolean) -> ();
	writeu16: (self: stream,  val: number, is_big_endian: boolean) -> ();
	writei32: (self: stream,  val: number, is_big_endian: boolean) -> ();
	writeu32: (self: stream,  val: number, is_big_endian: boolean) -> ();
	writef32: (self: stream,  val: number, is_big_endian: boolean) -> ();
	writef64: (self: stream,  val: number, is_big_endian: boolean) -> ();
	readstring: (self: stream,  len: number) -> string;
	writestring: (self: stream,  val: string, count: number?) -> ();
	fill: (self: stream,  val: number, count: number?) -> ();
}

Stream = {}

function Stream.new(r: object): stream
	return disguise(setmetatable({referral = r; i = 0}, Stream))
end

function stream_f_inc(n: number, method: (object, ...any)->any)
	return function(self: stream, ...)
		local result = method(self.referral, self.i, ...)
		self:increment(n)
		return result
	end
end

function stream_f_prx_call()
	return function(self: stream, ...)
		return self.referral, ...
	end
end

function stream_f_deprecated(s: string?)
	return function()
		error(s or 'Method is deprecated or unimplemented')
	end
end

function Stream.readstring(self: stream, len: number)
	local result = self.referral:readstring(self.i, len)
	self:increment(len)
	return result
end

function Stream.writestring(self: stream, val: string, count: number?)
	self.referral:writestring(self.i, val, count)
	self:increment(count or #val)
end

function Stream.get_bytes(self: stream, len: number?)
	local result = self.referral:get_bytes(self.i, len)
	self:increment(#result)
	return result
end

function Stream.write_bytes(self: stream, ...)
	self.referral:write_bytes(self.i, ...)
	self:increment(select('#', ...))
end

function Stream.fill(self: stream, val: number, count: number?)
	self.referral:fill(self.i, val, count)
	if count then
		self:increment(count)
	else
		self.i = self:len()
	end
end

function Stream.increment(self: stream, i: number)self.i+=(i or 1)end

Stream.copy = stream_f_deprecated()
Stream.len = compose(stream_f_prx_call, module.len)
Stream.readi8 = stream_f_inc(1, module.readi8)
Stream.readu8 = stream_f_inc(1, module.readu8)
Stream.readi16 = stream_f_inc(2, module.readi16)
Stream.readu16 = stream_f_inc(2, module.readu16)
Stream.readi32 = stream_f_inc(4, module.readi32)
Stream.readu32 = stream_f_inc(4, module.readu32)
Stream.readf32 = stream_f_inc(4, module.readf32)
Stream.readf64 = stream_f_inc(8, module.readf64)
Stream.writei8 = stream_f_inc(1, module.writei8)
Stream.writeu8 = stream_f_inc(1, module.writeu8)
Stream.writei16 = stream_f_inc(2, module.writei16)
Stream.writeu16 = stream_f_inc(2, module.writeu16)
Stream.writei32 = stream_f_inc(4, module.writei32)
Stream.writeu32 = stream_f_inc(4, module.writeu32)
Stream.writef32 = stream_f_inc(4, module.writef32)
Stream.writef64 = stream_f_inc(8, module.writef64)
Stream.__len = Stream.len
Stream.read_float = Stream.readf32
Stream.write_float = Stream.writef32
Stream.read_double = Stream.readf64
Stream.write_double = Stream.writef64

Class.makeProperClass(Stream, '@CHL/BufferWrapper/Stream')

module.Stream = Stream

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Consumer = require('./@CHL>Consumer')

export type to_buffw_consumer = {
	size: number;
	chunks: number;
	buffw: object;
	
	build: (self: to_buffw_consumer)->object;
} & Consumer.object<number>

b_consumer = {}

function b_consumer.new(): to_buffw_consumer
	local self: to_buffw_consumer = Object.simple.new(b_consumer)
	
	self.size = 0
	self.buffw = module.from.size(0)
	
	return self
end

function b_consumer.build(self: to_buffw_consumer)
	self.buffw:realloc(self.size)
	return self.buffw
end

function b_consumer.consume(self: to_buffw_consumer, byte: number)
	local buffw = self.buffw
	
	if buffw:len() < self.size + 1 then
		buffw:realloc(buffw:len() + 0x100)
	end
	
	buffw:writeu8(self.size, byte)

	self.size += 1
end

Class.makeProperClass(b_consumer, '@CHL/BufferWrapper/Consumer')

module.consumer = b_consumer

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
