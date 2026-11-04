local Iterator = require('./@CHL>Iterator')
local BufferWrapper = require('./@CHL>BufferWrapper')
local Object = require('./Object')
local Class = require('./Class')
local Byte = require('./@CHL>Byte')
local StringUtils = require('./@CHL>StringUtils')
local Dash = require('./@roblox>Dash')

export type byte_iterator = StringUtils.byte_iterator -- standard here is going to be unsigned

local module = {}

Dash.promise:await()

compose = Dash.compose
disguise = require('./LuaUTypes').disguise
rshift = bit32.rshift
lshift = bit32.lshift
band = bit32.band
byte_clamp = Byte.bit_clamp
byte_slice = Byte.slice

--#####################################################################################
--#####################################################################################
--#####################################################################################

type buff_w = BufferWrapper.object

-- does read least significant bit first
export type reader = {
	iterator: byte_iterator;
	buffer: buff_w;
	byte: number;
	offset: number; -- [0, 7] but 8 in case of uninitialized
	
	can_read: (self: reader)-> boolean;
	read_bits: (self: reader, number)->(number);--lower or equal to 8, --larger than 0
	byte_align: (self: reader) -> ();
	
	get_bytes: (self: reader, amount: number)->{};
	read_float: (self: reader, is_big_endian: boolean?) -> number;
	read_double: (self: reader, is_big_endian: boolean?) -> number;
	readi8: (self: reader) -> number;
	readu8: (self: reader) -> number;
	readi16: (self: reader, is_big_endian: boolean?) -> number;
	readu16: (self: reader, is_big_endian: boolean?) -> number;
	readi32: (self: reader, is_big_endian: boolean?) -> number;
	readu32: (self: reader, is_big_endian: boolean?) -> number;
	readf32: (self: reader, is_big_endian: boolean?) -> number;
	readf64: (self: reader, is_big_endian: boolean?) -> number;
	readu64: (self: reader, is_big_endian: boolean?) -> number;
	read_string: (self: reader, len: number) -> string;
}

bor = bit32.bor

Reader = {}
Reader.from = {}

function Reader.new(iterator: byte_iterator): reader
	local self: reader = Object.simple.new(Reader)
	self.iterator = iterator
	self.buffer = BufferWrapper.from.size(8)
	self.byte = iterator:proceed()
	self.offset = 0

	return self
end

function Reader.can_read(self: reader): boolean
	return not not self.byte
end

function Reader.byte_align(self: reader)
	while self.offset ~= 0 do
		self:read_bits(1)
	end
end
--[[
	Reads bits_n bits from 1 to 8
	-> [12345678]
]]
function Reader.read_bits(self: reader, bits_n: number)
	local result = 0
	local byte = self.byte
	local offset = self.offset
	local new_offset = offset + bits_n
	local it = self.iterator
	
	assert(bits_n >= 0 or byte)
	
	local new_byte_written = new_offset >= 8
	
	if new_offset >= 8 then
		-- eval current stashed byte
		new_offset -= 8
		
		local _, right = byte_slice(byte, offset)
		
		result = right
		
		-- use iterator to offset result in bytes
		while new_offset >= 8 do
			new_offset -= 8

			local byte2 = assert(it:proceed())

			result = bor(lshift(result, 8), byte2)
		end
		
		byte = it:proceed()
		offset = 0
		
		if not byte then
			self.byte = disguise()
			
			return result
		end
	end
	
	-- use current byte
	local bits = byte_slice(byte, new_offset)
	local reverse = 8 - (new_offset - offset)
	--bits = lshift(bits, offset)
	_, bits = byte_slice(bits, reverse)
	result = bor(lshift(result, new_offset), bits)

	self.byte = byte
	self.offset = new_offset
	
	return result
end

function Reader.get_bytes(self: reader, amount: number)
	local result = table.create(amount, 0)
	
	for i in result do
		if not self.iterator:can_proceed() then
			break
		end
		result[i] = self:read_bits(8)
	end
	
	return result
end

function Reader.read_string(self: reader, len: number)
	local result = ''
	
	for i = 1, len do
		if not self.iterator:can_proceed() then
			break
		end
		result ..= string.char(self:read_bits(8))
	end
	
	return result
end

function factory_buffer_use_read(b_index: string, length: number)
	return function(self: reader, is_big_end: boolean)
		local buff = self.buffer
		
		for i = 1, length do
			assert(self:can_read(), 'unable to handle case where iterator is empty')
			buff:writeu8(i - 1, self:read_bits(8))
		end
		return buff[b_index](buff, 0, is_big_end)
	end
end

Reader.readi8 = factory_buffer_use_read('readi8', 1)
Reader.readu8 = factory_buffer_use_read('readu8', 1)
Reader.readi16 = factory_buffer_use_read('readi16', 2)
Reader.readu16 = factory_buffer_use_read('readu16', 2)
Reader.readi32 = factory_buffer_use_read('readi32', 4)
Reader.readu32 = factory_buffer_use_read('readu32', 4)
Reader.readf32 = factory_buffer_use_read('readf32', 4)
Reader.read_float = factory_buffer_use_read('readf32', 4)
Reader.readf64 = factory_buffer_use_read('readf64', 8)
Reader.read_double = factory_buffer_use_read('read_double', 8)
Reader.readu64 = factory_buffer_use_read('readu64', 8)

Reader.from.string = compose(StringUtils.iterator.byte.new, Reader.new) :: (string) -> reader

Class.make_proper_class(Reader, '@CHL>BinaryStream>Reader')

module.reader = Reader

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type msbit_reader = reader;

msbit_reader = {}
msbit_reader.from = {}

function msbit_reader.new(iterator: byte_iterator)
	local self: msbit_reader = Object.simple.new(msbit_reader)
	
	self.iterator = iterator
	self.buffer = BufferWrapper.from.size(8)
	self.byte = iterator:proceed()
	self.offset = 0
	
	return self
end

--[[
	Overly simplified version of reading bits.
	
	Reads bits from most sigificant (1) to least (8):
	
	 <-------  <-------
	[87654321][FEDCBA09]
]]
function msbit_reader.read_bits(self: msbit_reader, bits_amount: number)
	local byte, offset = self.byte, self.offset
	
	if bits_amount == 1 then
		local result = band(rshift(byte, offset), 0x01)
		
		offset += 1
		
		if offset >= 8 then
			byte = self.iterator:proceed()
			offset = 0
		end
		
		self.byte = byte
		self.offset = offset
		
		return result
	end
	
	local result = 0
	
	for i = 1, bits_amount do
		local bit = self:read_bits(1)
		
		result = bor(result, lshift(bit, i - 1))
	end
	
	return result
end

msbit_reader.byte_align = Reader.byte_align
msbit_reader.can_read = Reader.can_read
msbit_reader.get_bytes = Reader.get_bytes
msbit_reader.read_string = Reader.read_string
msbit_reader.readi8 = Reader.readi8
msbit_reader.readu8 = Reader.readu8
msbit_reader.readi16 = Reader.readi16
msbit_reader.readu16 = Reader.readu16
msbit_reader.readi32 = Reader.readi32
msbit_reader.readu32 = Reader.readu32
msbit_reader.readf32 = Reader.readf32
msbit_reader.read_float = Reader.readf32
msbit_reader.readf64 = Reader.readf64
msbit_reader.read_double = Reader.readf64
msbit_reader.readu64 = Reader.readu64

msbit_reader.from.string = compose(StringUtils.iterator.byte.new, msbit_reader.new) :: (string) -> msbit_reader

Class.make_proper_class(msbit_reader, '@CHL>BinaryStream>msbit_reader')

module.msbit_reader = msbit_reader

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Consumer = require('./@CHL>Consumer')

type byte_consumer = Consumer.object<number>

export type writer = {
	consumer: byte_consumer;
	buffer: buff_w;
	byte: number;
	offset: number; -- [0, 8] -- 8 indicates next
	
	write_bits: (self: writer, value: number, bits: number)->();
	write_bytes: (self: writer, ...number) -> ();
	write_string: (self: writer, s: string) -> ();

	writei8: (self: writer, value: number) -> ();
	writeu8: (self: writer, value: number) -> ();
	writei16: (self: writer, value: number, is_big_endian: boolean?) -> ();
	writeu16: (self: writer, value: number, is_big_endian: boolean?) -> ();
	writei32: (self: writer, value: number, is_big_endian: boolean?) -> ();
	writeu32: (self: writer, value: number, is_big_endian: boolean?) -> ();
	writef32: (self: writer, value: number, is_big_endian: boolean?) -> ();
	writef64: (self: writer, value: number, is_big_endian: boolean?) -> ();
	writeu64: (self: writer, value: number, is_big_endian: boolean?) -> ();
	
	write_ubyte: (self: writer, value: number)->();
	write_float: (self: writer, value: number, is_big_endian: boolean?) -> ();
	write_double: (self: writer, is_big_endian: boolean?) -> ();
	write_ushort: (self: writer, value: number, is_big_endian: boolean?) -> ();
}

Writer = {}

function Writer.new(consumer: byte_consumer): writer
	local self: writer = Object.simple.new(Writer)
	self.consumer = consumer or Consumer.print
	self.buffer = BufferWrapper.from.size(8)
	self.offset = 0
	self.byte = 0

	return self
end

--[[
	Attempts to write bits_n bits from 1 to 8 using value, 
	input: [12345678]
	-->
	object stashed byte: [12345678]
	
	Notes:
	input bits are extracted 8 and before depending on bits_n, then placed from left to right on object stashed byte by 
	shifting byte to the left
]]
function Writer.write_bits(self: writer, value: number, bits_n: number)
	local offset = self.offset
	local byte = self.byte
	local consumer = self.consumer
	local new_offset = bits_n + offset
	local did_change_byte = new_offset >= 8
	
	
	-- change byte case
	if did_change_byte then
		-- case to fill remaining byte
		if offset > 0 then
			new_offset -= 8
			
			local bits_filling = 8 - offset
			local value_lshifted = rshift(value, bits_n - bits_filling)
			local consumed_byte = bor(lshift(byte, bits_filling), value_lshifted)
			
			consumer:consume(consumed_byte)
		end
		
		-- direct consuming bytes
		while new_offset >= 8 do
			new_offset -= 8
			local current_byte = byte_clamp(rshift(value, new_offset))
			consumer:consume(current_byte)
		end
		
		byte = 0
		offset = 0
	end
	
	-- anything left in value
	if new_offset > 0 then
		local value_size = (new_offset - offset)
		value = byte_clamp(value, 8 - value_size)
		
		byte = bor(lshift(byte, value_size), value)
	end
	
	self.byte = byte
	self.offset = new_offset
end

function Writer.write_bytes(self: writer, ...: number)
	local n = select('#', ...)
	
	for i = 1, n do
		local v = select(i, ...)
		
		self:write_bits(v, 8)
	end
end

function Writer.write_string(self: writer, s: string)
	local n = #s
	for i = 1, n do
		self:write_bytes(s:byte(i))
	end
end

function factory_buffer_use_write(b_index: string, length: number)
	return function(self: writer, value: any, is_big_end: boolean?)
		local buff = self.buffer
		buff[b_index](buff, 0, value, is_big_end)

		self:write_bytes(unpack(buff:get_bytes(0, length)))
	end
end

Class.make_proper_class(Writer, '@CHL>BinaryStream>Writer')

Writer.writei8 = factory_buffer_use_write('writei8', 1)
Writer.writeu8 = factory_buffer_use_write('writeu8', 1)
Writer.writei16 = factory_buffer_use_write('writei16', 2)
Writer.writeu16 = factory_buffer_use_write('writeu16', 2)
Writer.writei32 = factory_buffer_use_write('writei32', 4)
Writer.writeu32 = factory_buffer_use_write('writeu32', 4)
Writer.writef32 = factory_buffer_use_write('writef32', 4)
Writer.write_float = factory_buffer_use_write('writef32', 4)
Writer.writef64 = factory_buffer_use_write('writef64', 8)
Writer.write_double = factory_buffer_use_write('write_double', 8)
Writer.writeu64 = factory_buffer_use_write('writeu64', 8)

module.writer = Writer

return module
