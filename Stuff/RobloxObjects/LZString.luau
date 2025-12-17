--[[
	currently no support for extended bits_per_pixel

	LZstring format at least from how I interpret it:
	
	A compressed LZstring format is arranged in atomic/bit level, as an array of bit segments. 
	All segments are bit reversed, meaning if bytes in the string are stored internally as bits [01234567],
	then the actual value when extracting reads 0 to 7, in bits stored internally, it's 7 to 0. ([76543210])
	
	For example, character 'a' is internally stored as 01100001, it appears in a compressed string as 1000011
	
	Each bit segment is arranged with a control value, of varying size starting with 2 bits.
	Then increases to 3 bits immediately after
	
	Control value meaning (based on value):
	 * 0: next segment is a byte of an ascii character
	 * 1: next segment is a 16 bit character
	   * For the above, 0 and 1, the segment is concattenated with current string, on some cases.
	 * 2: termination control value
	 * 3+: index of a dictionary to repeat

]]

local module = {}

local StringUtils = require('./@CHL>StringUtils')
local BinaryStream = require('./@CHL>BinaryStream')
local Iterator = require('./@CHL>Iterator')
local Object = require('./Object')
local Class = require('./Class')
local Map = require('./@CHL>Map')
local Set = require('./@CHL>Set')

type dict<T> = Map.dictionary<T>
type writer = BinaryStream.writer
type byte_iterator = StringUtils.byte_iterator
type simple_iterator<A, B...> = Iterator.simple<A, B...>
type set<T> = Set.simple<T>

export type compressor = {
	uncompressed: byte_iterator;
	writer: writer;
	
	dictionary: dict<number>;
	dictionary_size: number;
	dictionary_to_create: set<string>;
	
	current_string: string; -- context_w
	dictionary_check: string; -- context_wc
	
	-- denotes some kind of size in compressed data
	num_bits: number;
	-- denotes some kind of draining variable, used to grow num_bits
	drain: number;
	
	at_end: boolean;
	
	evaluate_current: (self: compressor)->();
	decrement_drain: (self: compressor)->();
	
	-- serves the similar purpose as self.writer:write_bits but value is inserted to
	-- the consumer in reverse order of bits
	write_bits: (self: compressor, value: number, num_bits: number)->();
	
	get_queue: (self: compressor) -> {number}
} & simple_iterator<number>

Compressor = {}
lshift = bit32.lshift
rshift = bit32.rshift
band = bit32.band
bor = bit32.bor
tinsert = table.insert

function Compressor.new(uncompressed: byte_iterator): compressor
	local self: compressor = Object.simple.new(Compressor)
	
	self.uncompressed = uncompressed
	self.writer = BinaryStream.writer.new({
		queue = {};
		consume = function(self, byte)
			tinsert(self.queue, byte)
		end,
	})
	self.dictionary_to_create = {}
	self.dictionary = {}
	self.dictionary_size = 3
	self.current_string = ''
	self.dictionary_check = ''
	self.num_bits = 2
	self.drain = 2
	self.at_end = false
	
	return self
end

function Compressor.decrement_drain(self: compressor)
	self.drain -= 1

	if self.drain <= 0 then
		self.drain = lshift(1, self.num_bits)
		self.num_bits += 1
	end
end

function Compressor.write_bits(self: compressor, value: number, num_bits: number)
	for i = 1, num_bits do
		self.writer:write_bits(band(value, 1), 1)
		value = rshift(value, 1)
	end
end

function Compressor.evaluate_current(self: compressor)
	local writer = self.writer
	local num_bits = self.num_bits
	local current = self.current_string
	
	if not self.dictionary_to_create[current] then
		local value = self.dictionary[current]
		
		self:write_bits(value, num_bits)
	else
		local first_byte = current:byte()
		if first_byte < 256 then
			self:write_bits(0, num_bits)
			self:write_bits(first_byte, 8)
		else
			self:write_bits(1, num_bits)
			self:write_bits(first_byte, 16)
		end
		
		self:decrement_drain()
		
		self.dictionary_to_create[current] = nil
	end
	
	self:decrement_drain()
end

function Compressor.get_queue(self: compressor): {number}
	return self.writer.consumer.queue
end

function Compressor.can_proceed(self: compressor): boolean
	return not self.at_end or #self:get_queue() > 0
end

function Compressor.proceed(self: compressor)
	local queue = self:get_queue()
	
	if #queue > 0 then
		local byte = table.remove(queue, 1)
		return byte
	end
	
	local uncompressed = self.uncompressed
	
	-- loop attempts to add new values to the queue
	while true do
		if uncompressed:can_proceed() then
			local byte = uncompressed:proceed()
			local char = string.char(byte)

			if not self.dictionary[char] then
				self.dictionary[char] = self.dictionary_size
				self.dictionary_size += 1
				self.dictionary_to_create[char] = true
			end

			local dictionary_check = self.current_string .. char;
			self.dictionary_check = dictionary_check

			if self.dictionary[dictionary_check] then
				self.current_string = dictionary_check
				continue
			else
				self:evaluate_current()
				
				--[[
            // Add wc to the dictionary.
            context_dictionary[context_wc] = context_dictSize++;
            context_w = String(context_c);
				]]
				
				self.dictionary[dictionary_check] = self.dictionary_size
				self.dictionary_size += 1
				self.current_string = char
				
				if #queue == 0 then
					continue
				end
			end
		else
			if #self.current_string ~= 0 then
				self:evaluate_current()
			end
			
			self:write_bits(2, self.num_bits)
			
			repeat
				self:write_bits(0, 1)
			until self.writer.offset <= 0

			self.at_end = true
		end
		break
	end
	
	if #queue > 0 then
		return self:proceed()
	else
		print(self)
		error('queue empty here')
	end
end

Iterator.simple.declare_as(Compressor)

Class.makeProperClass(Compressor, '@CHL>LZString>Compressor')

-- the next few functions offer a more convenient interface to the module
-- all inputs are in forms of arguments, returned string to string
Compressor.functions = {}

function Compressor.functions.default(s: string): string
	local byte_iterator = StringUtils.iterator.byte.new(s)
	local byte_consumer = StringUtils.consumer.byte.new()
	
	local compressor = Compressor.new(byte_iterator)
	
	for v in compressor do
		byte_consumer:consume(v)
	end
	
	return byte_consumer:get_string()
end

module.compressor = Compressor

--#####################################################################################
--#####################################################################################
--#####################################################################################

type reader = BinaryStream.reader
type map<I,V> = Map.simple<I,V>

export type decompressor = {
	compressed: byte_iterator;
	reader: reader;
	
	dictionary: map<number, string>;
	dictionary_size: number;
	
	queue: {number};
	
	drain: number;
	at_end: boolean;
	control_value_length: number;
	current_control_value: number;
	current_string: string;
	current_entry: string;
	
	decrement_drain: (self: decompressor)->();
	
	-- serves the similar purpose as self.reader:read_bits but value is inserted to
	-- the consumer in reverse order of bits
	read_bits: (self: decompressor, num_bits: number)->number;
	read_control_value: (self: decompressor)->number
} & simple_iterator<number>

Decompressor = {}

function Decompressor.new(compressed: byte_iterator): decompressor
	local self: decompressor = Object.simple.new(Decompressor)

	self.compressed = compressed
	self.reader = BinaryStream.reader.new(compressed)
	self.control_value_length = 3
	self.dictionary_size = 4
	self.current_control_value = nil;
	self.drain = 4
	self.current_entry = ''
	self.queue = {}
	self.dictionary = {}
	
	return self
end

function Decompressor.read_bits(self: decompressor, num_bits: number): number
	local result = 0
	local reader = self.reader
	local last = num_bits - 1
	
	for i = 0, last do
		local bit = reader:read_bits(1)
		local mask = lshift(bit, i)
		result = bor(result, mask)
	end
	return result
end

function Decompressor.decrement_drain(self: decompressor)
	self.drain -= 1
	if self.drain == 0 then
		self.drain = lshift(1, self.control_value_length)
		self.control_value_length += 1
	end
end

function Decompressor.read_control_value(self: decompressor)
	return self:read_bits(self.control_value_length)
end

function Decompressor.can_proceed(self: decompressor)
	return self.current_control_value ~= 2 or #self.queue > 0
end

function Decompressor.proceed(self: decompressor)
	if not self.current_control_value then
		self.current_control_value = self:read_bits(2)
	end
	
	if not self:can_proceed() then return;end
	
	if #self.queue > 0 then
		return table.remove(self.queue, 1)
	end
	
	local current_control_value = self.current_control_value
	local dictionary = self.dictionary
	
	if not dictionary[3] then
		local to_write = ""
		local value;
		
		-- functionality almost same as below
		if current_control_value == 0 then
			value = self:read_bits(8)
			to_write = string.char(value)
		elseif current_control_value == 1 then
			error('unable to handle non 8 bit characters')
		elseif current_control_value ~= 2 then
			error('invalid control value: ' .. current_control_value)
		end
		
		dictionary[3] = to_write
		self.current_string = to_write

		local n = #to_write

		for i = 1, n do
			local byte = to_write:byte(i)
			tinsert(self.queue, byte)
		end
		
	elseif self.reader:can_read() then
		local byte
		
		if current_control_value == 0 then
			byte = self:read_bits(8)
			
			-- same as case when control_value == 1
			dictionary[self.dictionary_size] = string.char(byte)
			current_control_value = self.dictionary_size
			self.dictionary_size += 1
			self:decrement_drain()
		elseif current_control_value == 1 then
			error('unable to handle non 8 bit characters')
		elseif current_control_value == 2 then
			warn('how did we get here?')
			return
		end
		
		
		if dictionary[current_control_value] then
			self.current_entry = dictionary[current_control_value]
		else
			if current_control_value == self.dictionary_size then
				self.current_entry = self.current_string .. self.current_string:sub(1, 1)
			else
				error('how did we get here?')
			end
		end
		
		local n = #self.current_entry
		
		for i = 1, n do
			local byte = self.current_entry:byte(i)
			tinsert(self.queue, byte)
		end
		
		dictionary[self.dictionary_size] = self.current_string .. self.current_entry:sub(1,1)
		self.dictionary_size += 1
		self.current_string = self.current_entry
		
		self:decrement_drain()
	end

	current_control_value = self:read_control_value()
	self.current_control_value = current_control_value
	
	if #self.queue > 0 then
		return self:proceed()
	else
		print(self)
		error('how did we get here?')
	end
end

Iterator.simple.declare_as(Decompressor)

Class.makeProperClass(Decompressor, '@CHL>LZString>Decompressor')

-- the next few functions offer a more convenient interface to the module
-- all inputs are in forms of arguments, returned string to string
Decompressor.functions = {}

function Decompressor.functions.default(s: string): string
	local byte_iterator = StringUtils.iterator.byte.new(s)
	local byte_consumer = StringUtils.consumer.byte.new()

	local decompressor = Decompressor.new(byte_iterator)
	
	while decompressor:can_proceed() do
		byte_consumer:consume(decompressor:proceed())
	end

	return byte_consumer:get_string()
end

module.decompressor = Decompressor

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
