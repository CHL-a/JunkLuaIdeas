local Dash = require('./@CHL>DashSingular')
local Iterator = require('./@CHL>Iterator')
local BufferWrapper = require('./@CHL>BufferWrapper')
local Class = require('./Class')

module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Object = require('./Object')

export type byte = number

export type readable = {
	length: number;

	peek: (self: readable, i: number) -> number?;
} --& Object.object_inheritance

Readable = {}

--[[
function Readable.new(): readable
	local self: readable = Object.from.class(Readable)
	
	return self
end

Readable.peek = Class.abstractMethod

Class.makeProperClass(Readable, '@CHL>Base64>Readable')
]]

module.readable = Readable

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type string_readable = {
	referral: string;
} & --Class.subclass<
	readable-->

StringReadable = {}

function StringReadable.new(r: string): string_readable
	local self: string_readable = Object.simple.new(StringReadable)
	--Readable.new():__inherit(StringReadable)
	
	self.length = #r
	self.referral = r
	
	return self
end

function StringReadable.peek(self: string_readable, i: number)
	i += 1
	return if (i>= 1 and i<= self.length) 
		then self.referral:sub(i,i):byte()
		else nil
end

Class.makeProperClass(StringReadable, '@CHL>Base64>Readable>String')

Readable.string = StringReadable

--#####################################################################################
--#####################################################################################
--#####################################################################################

type bufferw = BufferWrapper.object

export type bufferw_readable = {
	referral: bufferw;
} & --Class.subclass<
	readable-->

compose = Dash.compose
BufferWReadable = {}
BufferWReadable.from = {}

function BufferWReadable.new(b: bufferw): bufferw_readable
	local self: bufferw_readable = Object.simple.new(BufferWReadable)
		--Readable.new():__inherit(BufferWReadable)
	
	self.length = b:len()
	self.referral = b
	
	return self
end

function BufferWReadable.peek(self: bufferw_readable, i: number)
	return if (i >= 0 and i < self.length) then
		self.referral[i]
		else nil
end

BufferWReadable.from.buffer = compose(BufferWrapper.new, BufferWReadable.new)

Class.makeProperClass(BufferWReadable, '@CHL>Base64>Readable>BufferWrapper')

Readable.bufferw = BufferWReadable

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Math = require('./@CHL>Math')

export type encoder = {
	length: number;
	readable: readable;
	alphabet: {number};
	padding: number;
	current_set: number;
	batch: {number};
	batch_index: number;
} & Iterator.simple<byte
	--, byte, byte, byte
	>

Encoder = {}
alphabet = table.create(63, 0xFF)
padding = ('='):byte()
band = bit32.band
rshift = bit32.rshift
lshift = bit32.lshift
gdiv = Math.glass_div

function Encoder.new(r: readable): encoder
	local self: encoder = Object.simple.new(Encoder) -- Iterator.new():__inherit(Encoder)
	
	self.readable = r
	self.alphabet = alphabet
	self.padding = padding
	self.current_set = 0
	self.length = gdiv(self.readable.length, 3) * 4
	self.batch = {}
	self.batch_index = 5;
	
	return self
end

function Encoder.can_proceed(self: encoder)
	local set_limit = gdiv(self.readable.length, 3)
	return self.current_set < set_limit or self.batch_index <= 4
end

function Encoder.proceed(self: encoder)
	local batch = self.batch
	
	if self.batch_index > 4 then
		local r = self.readable
		local alphabet = self.alphabet
		local set = self.current_set
		local padding = self.padding

		local b_0, b_1, b_2 = 
			r:peek(set * 3),
			r:peek(set * 3 + 1),
			r:peek(set * 3 + 2)

		self.current_set += 1


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
		
		
		batch[1] = r_0
		batch[2] = r_1
		batch[3] = r_2
		batch[4] = r_3
		self.batch_index = 1
	end
	
	local batch_index = self.batch_index
	self.batch_index += 1
	
	return batch[batch_index]
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
	length: number;
	readable: readable;
	alphabet: {number};
	padding: number;
	current_set: number;
	batch: {number};
	batch_index: number;
	
	reverse_alphabet_get: (self: decoder, v: number) -> number?;
} & Iterator.simple<byte-- , byte, byte>
	>
Decoder = {}

function Decoder.new(r: readable): decoder
	local r_len = r.length
	assert(r_len % 4 == 0, 'Readable not in sets of four')
	
	local self: decoder = Object.simple.new(Decoder) -- Iterator.new():__inherit(Decoder)
	
	self.readable = r
	self.alphabet = alphabet
	self.padding = padding
	self.current_set = 0
	self.length = (r_len / 4) * 3 +
		(if r:peek(r_len - 2) == padding then -1 else 0) + 
		(if r:peek(r_len - 1) == padding then -1 else 0)
	self.batch = {}
	self.batch_index = 4
	
	return self
end

function Decoder.can_proceed(self: decoder)
	local set_limit = gdiv(self.readable.length, 4)
	return self.current_set < set_limit or self.batch[self.batch_index]
end

function Decoder.reverse_alphabet_get(self: decoder, v: number)
	local needle = table.find(self.alphabet, v)
	
	return needle
end

function Decoder.proceed(self: decoder)
	local batch = self.batch
	
	if self.batch_index >= 4 then
		local r = self.readable
		local alphabet = self.alphabet
		local set = self.current_set
		local padding = self.padding
		
		local b_0, b_1, b_2, b_3 = 
			self:reverse_alphabet_get(r:peek(set * 4    )),
			self:reverse_alphabet_get(r:peek(set * 4 + 1)),
			self:reverse_alphabet_get(r:peek(set * 4 + 2)),
			self:reverse_alphabet_get(r:peek(set * 4 + 3))
		self.current_set += 1
		
		local r_0, r_1, r_2
		
		r_0 = lshift(b_0, 2) + rshift(band(b_1, 0x30), 4)
		
		if b_2 then
			r_1 = lshift(band(b_1, 0x0F), 4) + rshift(band(b_2, 0x3C), 2)
			
			if b_3 then
				r_2 = lshift(band(b_2, 0x03), 6) + band(b_3, 0x3F)
			end
		end
		
		batch[1] = r_0
		batch[2] = r_1
		batch[3] = r_2
		
		self.batch_index = 1
	end

	local batch_index = self.batch_index
	self.batch_index += 1
	
	return batch[batch_index]
end

Decoder.__iter = Iterator.simple.__iter

Class.makeProperClass(Decoder, '@CHL>Base64>Decoder')

module.decoder = Decoder

return module
