local Dash = require('./@CHL>DashSingular')
local Iterator = require('./@CHL>Iterator')
local BufferWrapper = require('./@CHL>BufferWrapper')
local Class = require('./Class')
local Consumer = require('./@CHL>Consumer')

module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

function module.expected_encoded_size(decoded_size: number)
	return gdiv(decoded_size, 3) * 4
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Object = require('./Object')
local Math = require('./@CHL>Math')

export type s_iter<T, U...> = Iterator.simple<T, U...>
export type byte = number
export type byte_consumer = Consumer.object<byte>
export type byte_iterator = s_iter<byte>

export type encoder = {
	iterator: byte_iterator;
	consumer: byte_consumer;
	alphabet: {number};
	padding: number;
	i: number;
} & s_iter<number> -- returns 1 based index of the byte position of an evaluated encoded process

Encoder = {}
alphabet = table.create(63, 0xFF)
padding = ('='):byte()
band = bit32.band
rshift = bit32.rshift
lshift = bit32.lshift
gdiv = Math.glass_div

function Encoder.new(it: byte_iterator, con: byte_consumer): encoder
	local self: encoder = Object.simple.new(Encoder) -- Iterator.new():__inherit(Encoder)
	
	self.iterator = it
	self.consumer = con
	self.alphabet = alphabet
	self.padding = padding
	self.i = 1
	
	return self
end

function Encoder.can_proceed(self: encoder)
	return self.iterator:can_proceed()
end

function Encoder.proceed(self: encoder)
	local it = self.iterator
	local alphabet = self.alphabet
	local padding = self.padding
	local con = self.consumer
	
	local b_0, b_1, b_2 = it:proceed(), it:proceed(), it:proceed()
	local r_0, r_1, r_2, r_3 = nil, nil, padding, padding

	local i_0, i_1, i_2, i_3 = 
		rshift(band(b_0, 0xFC), 2),
		lshift(band(b_0, 0x03), 4) + rshift(band(b_1 or 0, 0xF0), 4),
		nil,
		nil

	r_0 = alphabet[i_0]
	r_1 = alphabet[i_1]

	if b_1 then
		i_2 = lshift(band(b_1, 0x0F), 2) + rshift(band(b_2 or 0, 0xC0), 6)
		r_2 = alphabet[i_2]

		if b_2 then
			i_3 = rshift(band(b_2, 0x3F), 0)
			r_3 = alphabet[i_3]
		end
	end
	
	con:consume(r_0)
	con:consume(r_1)
	con:consume(r_2)
	con:consume(r_3)
	
	local result = self.i
	
	self.i += 4
	
	return result
end


Encoder.__iter = Iterator.simple.__iter
module.alphabet = alphabet
module.padding = padding

Class.makeProperClass(Encoder, '@CHL>Base64>Encoder')

module.encoder = Encoder

--#####################################################################################
--#####################################################################################
--#####################################################################################

availible = 0

function add_to_alphabet(range: string)
	local l = range:byte(2)
	for i = range:byte(1), l do
		module.alphabet[availible] = i
		availible += 1
	end
end

add_to_alphabet'AZ'
add_to_alphabet'az'
add_to_alphabet'09'
module.alphabet[62] = ('+'):byte()
module.alphabet[63] = ('/'):byte()

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type decoder = {
	alphabet: {number};
	padding: number;
	iterator: byte_iterator;
	consumer: byte_consumer;
	i: number;
	
	reverse_alphabet_get: (self: decoder, v: number) -> number?;
} & s_iter<number> -- cu

Decoder = {}

function Decoder.new(it: byte_iterator, con: byte_consumer): decoder
	local self: decoder = Object.simple.new(Decoder) -- Iterator.new():__inherit(Decoder)
	
	self.alphabet = alphabet
	self.padding = padding
	self.iterator = it;
	self.consumer = con
	self.i = 1
	
	return self
end

function Decoder.can_proceed(self: decoder)
	return self.iterator:can_proceed()
end

function Decoder.reverse_alphabet_get(self: decoder, v: number)
	for i, w in self.alphabet do
		if w == v then
			return i
		end
	end
end

function Decoder.proceed(self: decoder)
	local it = self.iterator
	local con = self.consumer
	local alphabet = self.alphabet
	local padding = self.padding

	local b_0, b_1, b_2, b_3 = 
		it:proceed(),
		it:proceed(),
		it:proceed(),
		it:proceed()

	b_0 = self:reverse_alphabet_get(b_0)
	b_1 = self:reverse_alphabet_get(b_1)
	b_2 = self:reverse_alphabet_get(b_2)
	b_3 = self:reverse_alphabet_get(b_3)

	local r_0, r_1, r_2
	
	r_0 = lshift(b_0, 2) + rshift(band(b_1, 0x30), 4)
		
	if b_2 then
		r_1 = lshift(band(b_1, 0x0F), 4) + rshift(band(b_2, 0x3C), 2)
		
		if b_3 then
			r_2 = lshift(band(b_2, 0x03), 6) + band(b_3, 0x3F)
		end
	end
	
	con:consume(r_0)
	if r_1 then
		con:consume(r_1)
	end
	if r_2 then
		con:consume(r_2)
	end
	
	local result = self.i
	
	self.i += 3
	
	return result
end

Decoder.__iter = Iterator.simple.__iter

Class.makeProperClass(Decoder, '@CHL>Base64>Decoder')

module.decoder = Decoder

--#####################################################################################
--#####################################################################################
--#####################################################################################

local StringUtils = require('./@CHL>StringUtils')

All = {}

function All.encode_from_buffer(buffer_arg: buffer): string
	local iterator = BufferWrapper.iterator.new(buffer_arg)
	local consumer = StringUtils.consumer.byte.new()
	
	local encoder = Encoder.new(iterator, consumer)
	
	while encoder:can_proceed() do
		encoder:proceed()
	end
	
	return consumer:get_string()
end

module.all = All

return module
