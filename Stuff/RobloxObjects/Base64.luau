local Dash = require('./@roblox>Dash')
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
	
	all: (self: encoder)->();
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
	local struct = {
		alphabet = alphabet,
		padding = padding,
		bytes = {b_0, b_1, b_2}
	}
	
	local r_0, r_1, r_2, r_3 = Encoder.parse_chunk(struct)
	
	con:consume(r_0)
	con:consume(r_1)
	con:consume(r_2)
	con:consume(r_3)
	
	local result = self.i
	
	self.i += 4
	
	return result
end

function Encoder.all(self: encoder)
	while self:can_proceed() do
		self:proceed()
	end
end

export type encoder_struct = {
	bytes: {number};
	alphabet: {number};
	padding: number;
}

function Encoder.parse_chunk(struct: encoder_struct): (number, number, number, number)
	local b_0, b_1, b_2 = unpack(struct.bytes)
	local padding, alphabet = struct.padding, struct.alphabet
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
	
	return r_0, r_1, r_2, r_3
end

Encoder.__iter = Iterator.simple.__iter
module.alphabet = alphabet
module.padding = padding

Class.make_proper_class(Encoder, '@CHL>Base64>Encoder')

module.encoder = Encoder

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

local LinkedQueue = require('./@CHL>LinkedQueue')

type queue<T> = LinkedQueue.object<T>

export type encoder_iterator = {
	iterator: byte_iterator;
	queue: queue<number>;
	alphabet: {number};
	padding: number;
	i: number;
} & s_iter<number> -- returns 1 based index of the byte position of an evaluated encoded process

encoder_iterator = {}

function encoder_iterator.new(it: byte_iterator): encoder_iterator
	local self: encoder_iterator = Object.simple.new(encoder_iterator) -- Iterator.new():__inherit(Encoder)
	
	self.iterator = it
	self.queue = LinkedQueue.default.new()
	self.alphabet = alphabet
	self.padding = padding
	self.i = 1
	
	return self
end

function encoder_iterator.can_proceed(self: encoder_iterator)
	return self.iterator:can_proceed() or not self.queue:is_empty()
end

function encoder_iterator.proceed(self: encoder_iterator)
	local queue = self.queue
	
	if not queue:is_empty() then
		return queue:dequeue()
	end
	
	local it = self.iterator
	local alphabet = self.alphabet
	local padding = self.padding
	local con = self.consumer
	
	local b_0, b_1, b_2 = it:proceed(), it:proceed(), it:proceed()
	local struct = {
		alphabet = alphabet,
		padding = padding,
		bytes = {b_0, b_1, b_2}
	}
	
	local r_0, r_1, r_2, r_3 = Encoder.parse_chunk(struct)
	
	queue:enqueue(r_0)
	queue:enqueue(r_1)
	queue:enqueue(r_2)
	queue:enqueue(r_3)
	
	local result = self.i
	
	self.i += 4
	
	return queue:dequeue()
end

Class.make_proper_class(encoder_iterator, '@CHL>Base64>EncoderIterator')

Encoder.encoder_iterator = encoder_iterator

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

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

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

export type decoder = {
	alphabet: {number};
	padding: number;
	iterator: byte_iterator;
	consumer: byte_consumer;
	i: number;
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

function Decoder.reverse_alphabet_get(alphabet: {number}, v: number): number
	for i, w in alphabet do
		if w == v then
			return i
		end
	end
end

function Decoder.proceed(self: decoder)
	local it = self.iterator
	local con = self.consumer
	local alphabet = self.alphabet

	local b_0, b_1, b_2, b_3 = 
		it:proceed(),
		it:proceed(),
		it:proceed(),
		it:proceed()
	
	local struct = {}
	struct.alphabet = alphabet
	struct.bytes = {b_0, b_1, b_2, b_3}
	
	local r_0, r_1, r_2 = Decoder.parse_chunk(struct)
	
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

export type decoder_struct = {
	bytes: {number};
	alphabet: {number};
}

function Decoder.parse_chunk(decoder_struct: decoder_struct): (number, number?, number?)
	local b_0, b_1, b_2, b_3 = unpack(decoder_struct.bytes)
	local alphabet = decoder_struct.alphabet
	
	b_0 = Decoder.reverse_alphabet_get(alphabet, b_0)
	b_1 = Decoder.reverse_alphabet_get(alphabet, b_1)
	b_2 = Decoder.reverse_alphabet_get(alphabet, b_2)
	b_3 = Decoder.reverse_alphabet_get(alphabet, b_3)
	
	local r_0, r_1, r_2
	
	r_0 = lshift(b_0, 2) + rshift(band(b_1, 0x30), 4)
		
	if b_2 then
		r_1 = lshift(band(b_1, 0x0F), 4) + rshift(band(b_2, 0x3C), 2)
		
		if b_3 then
			r_2 = lshift(band(b_2, 0x03), 6) + band(b_3, 0x3F)
		end
	end
	
	return r_0, r_1, r_2
end

Decoder.__iter = Iterator.simple.__iter

Class.make_proper_class(Decoder, '@CHL>Base64>Decoder')

module.decoder = Decoder

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

export type decoder_iterator = {
	alphabet: {number};
	padding: number;
	iterator: byte_iterator;
	queue: queue<number>;
	i: number;
	
	reverse_alphabet_get: (self: decoder, v: number) -> number?;
} & s_iter<number> -- cu

decoder_iterator = {}

function decoder_iterator.new(it: byte_iterator): decoder_iterator
	local self: decoder = Object.simple.new(decoder_iterator) -- Iterator.new():__inherit(Decoder)
	
	self.alphabet = alphabet
	self.padding = padding
	self.iterator = it;
	self.queue = LinkedQueue.default.new()
	self.i = 1
	
	return self
end

function decoder_iterator.proceed(self: decoder_iterator)
	local queue = self.queue
	if not queue:is_empty() then
		return queue:dequeue()
	end
	
	local it = self.iterator
	local con = self.consumer
	local alphabet = self.alphabet
	
	local b_0, b_1, b_2, b_3 = 
		it:proceed(),
		it:proceed(),
		it:proceed(),
		it:proceed()
	
	local struct = {}
	struct.alphabet = alphabet
	struct.bytes = {b_0, b_1, b_2, b_3}
	
	local r_0, r_1, r_2 = Decoder.parse_chunk(struct)
	
	queue:enqueue(r_0)
	
	if r_1 then
		queue:enqueue(r_1)
	end
	
	if r_2 then
		queue:enqueue(r_2)
	end
	
	local result = self.i
	
	self.i += 3
	
	return queue:dequeue()
end

decoder_iterator.reverse_alphabet_get = Decoder.reverse_alphabet_get
decoder_iterator.can_proceed = encoder_iterator.can_proceed

Class.make_proper_class(decoder_iterator, '@CHL>Base64>Decoder>Iterator')

Decoder.decoder_iterator = decoder_iterator

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################


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

function All.decode_from_string(string_arg: string): BufferWrapper.object
	local iterator = StringUtils.iterator.byte.new(string_arg)
	local consumer = BufferWrapper.consumer.new()

	local decoder = Decoder.new(iterator, consumer)

	while decoder:can_proceed() do
		decoder:proceed()
	end

	return consumer:build()
end

module.all = All

return module
