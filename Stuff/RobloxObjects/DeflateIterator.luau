--[[
	Iterator implementation of https://github.com/davidm/lua-compress-deflatelua/blob/master/lmod/compress/deflatelua.lua
	
	This is explicitly not compliant
	
	Sources:
	 * rfc1950: https://www.rfc-editor.org/info/rfc1950
	 * rfc1951: https://www.rfc-editor.org/info/rfc1951
	 * https://pyokagan.name/blog/2019-10-18-zlibinflate/
	
	Current explaination as of Nov 1st, 2026:
	
	for purposes of this implementation, we'll define read_bits(x) as a function that extracts bit values from a msbit reader:
	
	 Bits read
	 <-------  <-------
	[87654321][GFEDCBA9]
	 ----------------->
	 Bytes read
	
	zlib & LZ77:
	 * for the header, it is defined as a ushort, obtained as big endian, containing multiple flags:
	   [iiiimmmm lldccccc]
	   i: compression info
	   m: compression method
	   l: level
	   d: dict flag
	   c: checksum: in order to validate the header, the ushort, c is calculated such that the ushort % 31 == 0
	 * for the literal table, default: it is as says but with some added clarification:
	+----------+------+------------+-----------+ * codes are fetched from a reader, which does read from the same source of reader
	|literals  |n_bits|codes (bin) |codes (dec)|   implementation but they are transformed such that the msbit fetched from the reader
	+----------+------+------------+-----------+   becomes the lsbit on binary
	|[0, 143]  |8     |00110000 to |[48, 191]  | * if there was a desire to make this table usable, then we would need a lookup table of
	|          |      |10111111    |           |   type map<code, literal>
	|[144, 255]|9     |110010000 to|[400, 511] |
	|          |      |111111111   |           |
	|[256, 279]|7     |0000000 to  |[0, 23]    |
	|          |      |0010111     |           |
	|[280, 287]|8     |11000000 to |[192, 199] |
	|          |      |11000111    |           |
	+----------+------+------------+-----------+
	 * after the block processing, bytes are realigned and there is also a uint (of unknown endianess) as a checksum
]]


local module = {}

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

local BinaryStream = require('./@CHL>BinaryStream')
local Dash = require('./@roblox>Dash')
local StringUtils = require('./@CHL>StringUtils')
local LinkedQueue = require('./@CHL>LinkedQueue')
local Iterator = require('./@CHL>Iterator')
local Object = require('./Object')
local Class = require('./Class')
local Huffman = require('./@CHL>Huffman')
local Adler32 = require('./@CHL>Adler32')

type queue<T> = LinkedQueue.object<T>
type reader = BinaryStream.msbit_reader
type length_value_table = Huffman.length_value_map<number>

export type inflate_zlib_header = {
	compression_method: number;
	compression_info: number;
	f_check: number;
	f_dict: boolean;
	f_level: number;
	window_size: number;
}

export type inflate_zlib = {
	queue: queue<number>;
	reader: BinaryStream.msbit_reader;
	has_completed_blocks: boolean;
	header: inflate_zlib_header;
	decompression_checksum: number;
	
	process_block: (self: inflate_zlib) -> ();
	fetch_value_from_code_table: (self: inflate_zlib, table: length_value_table) -> number;
} & Iterator.simple<number>

compose = Dash.compose
band = bit32.band
rshift = bit32.rshift
btest = bit32.btest
lshift = bit32.lshift
bor = bit32.bor

inflate_zlib = {}
inflate_zlib.from = {}

function inflate_zlib.new(reader: reader): inflate_zlib
	local self: inflate_zlib = Object.simple.new(inflate_zlib)
	
	self.reader = reader
	self.queue = LinkedQueue.default.new()
	self.has_completed_block = false
	self.header = self.parse_header(reader)
	self.decompression_checksum = 1
	
	self.has_completed_blocks = self:process_block()
	
	return self
end

function inflate_zlib.parse_header(reader: reader): inflate_zlib_header
	local result = {}
	local u16 = reader:readu16(true)
	local byte_0 = rshift(u16, 8)
	local byte_1 = band(u16, 0xFF)
	
	local compression_method = band(byte_0, 0xF)
	local compression_info = rshift(byte_0, 4)
	local f_check = band(byte_1, 0x1F)
	local f_dict = btest(band(byte_1, 0x20))
	local f_level = rshift(byte_1, 6)
	
	assert(compression_method == 8, `unrecognized zlib compression method: {compression_method}`)
	assert(compression_info <= 7, `invalid zlib window size: cinfo={compression_info}`)
	assert(u16 % 31 == 0, `bad zlib header: bad fcheck sum: {u16}`)
	
	if f_dict then
		error('unimplemented: FDICT')
	end
	
	result.compression_method = compression_method
	result.compression_info = compression_info
	result.f_check = f_check
	result.f_dict = f_dict
	result.f_level = f_level
	result.window_size = 2 ^ (compression_info + 8)
	
	return result
end

function inflate_zlib.parse_huffmantable(self: inflate_zlib, reader: reader): inflate_zlib_header
	--[[
	local hlit = bs:read(5)  -- # of literal/length codes - 257
	local hdist = bs:read(5) -- # of distance codes - 1
	local hclen = noeof(bs:read(4)) -- # of code length codes - 4
	]]
	local h_lit = reader:read_bits(5)
	local h_dist = reader:read_bits(5)
	local h_clen = assert(reader:read_bits(4))
	
	print(
		h_lit, h_dist, h_clen
	)
	
	error('incomplete')
end

function inflate_zlib.fetch_value_from_code_table(self: inflate_zlib, tab: length_value_table)
	local code = 0
	local code_bit_length = 0 -- set up for possible implicit or explicit max
	
	while true do
		local bit = self.reader:read_bits(1)
		code = bor(lshift(code, 1), bit)
		code_bit_length += 1
		
		local entry = tab[`{code_bit_length},{code}`]
		
		if entry then
			return entry
		end
	end
end

function inflate_zlib.process_block(self: inflate_zlib): number
	local reader = self.reader
	local is_complete = btest(reader:read_bits(1))
	local inflate_type = reader:read_bits(2)
	
	if inflate_type == inflate_zlib.magics.explicit_no_compression then
		while reader.offset ~= 0 do
			reader:read_bits(1)
		end
		
		local len = reader:read_bits(16)
		
		reader:read_bits(16) -- nlen_
		
		for i = 1, len do
			local byte = reader:read_bits(8)
			
			self.queue:enqueue(byte)
		end
	elseif inflate_type == inflate_zlib.magics.fixed_huffman or inflate_type == inflate_zlib.magics.dynamic_huffman then
		local literal_table
		
		if inflate_type == inflate_zlib.magics.fixed_huffman then
			literal_table = inflate_zlib.default_literal_table
		else
			-- self:parse_huffmantable(reader)
			error('incomplete')
		end
		
		repeat
			local code = self:fetch_value_from_code_table(literal_table)
			
			if code < 256 then
				self.queue:enqueue(code)
			elseif code == 256 then
				break
			else
				error(`unhandled: {code}`)
			end
			
		until false
	else
		error('incomplete:' .. inflate_type)
	end
	
	return is_complete
end

function inflate_zlib.proceed(self: inflate_zlib): number
	local queue = self.queue
	local reader = self.reader
	local result = queue:dequeue()
	
	self.decompression_checksum = Adler32.iterate(result, self.decompression_checksum)
	
	if queue:is_empty() then
		if self.has_completed_blocks then
			reader:byte_align()
			
			local checksum = reader:readu32(true)
			
			-- subject to check?
			--print(checksum)
			--print(self.decompression_checksum)
		else
			self.has_completed_blocks = self:process_block()
		end
	end
	
	return result
end

function inflate_zlib.can_proceed(self: inflate_zlib): number
	return not self.queue:is_empty() or not self.has_completed_blocks
end

function inflate_zlib.build_default_diff_table()
	local root = {}
	
	local brancher = Huffman.branch_builder.new(root)
	
	for i = 0, 31 do
		brancher:grow(32 + i, i, 5)
	end
	
	return Huffman.length_value_map.from.huffman_tree(root)
end

function inflate_zlib.build_default_literal_table()
	local root = {}
	local brancher = Huffman.branch_builder.new(root)
	
	-- see fixed huffman code literal table of deflate
	for literal = 0, 143 do
		local code = literal + 0b00110000
		brancher:grow(literal, code, 8)
	end
	
	for literal = 144, 255 do
		local code = literal - 144 + 0b110010000
		brancher:grow(literal, code, 9)
	end
	
	for literal = 256, 279 do
		local code = literal - 256 -- + 0b0000000
		brancher:grow(literal, code, 7)
	end
	
	for literal = 280, 287 do
		local code = literal - 280 + 0b11000000
		brancher:grow(literal, code, 8)
	end
	
	assert(Huffman.is_full(root))
	
	return Huffman.length_value_map.from.huffman_tree(root)
end

inflate_zlib.default_diff_table = inflate_zlib.build_default_diff_table()
inflate_zlib.default_literal_table = inflate_zlib.build_default_literal_table()

inflate_zlib.magics = {
	explicit_no_compression = 0;
	fixed_huffman = 1;
	dynamic_huffman = 2;
}
inflate_zlib.from.byte_iterator = compose(BinaryStream.msbit_reader.new, inflate_zlib.new) :: (Iterator.simple<number>)->inflate_zlib
inflate_zlib.from.string = compose(StringUtils.iterator.byte.new, inflate_zlib.from.byte_iterator) :: (string)->inflate_zlib

Class.make_proper_class(inflate_zlib, '@CHL>Deflate>inflate_zlib')

module.inflate_zlib = inflate_zlib

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

return module
