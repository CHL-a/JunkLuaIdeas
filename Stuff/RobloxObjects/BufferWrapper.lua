--// TYPES
local Objects = script.Parent

export type object = {
	referral: buffer;

	writeBytes: (self: object, offset: number, ...number) -> ();
	getBytes: (self: object, offset: number, len: number?) -> {number};
	readFloat: (self: object, offset: number) -> number;
	writeFloat: (self: object, offset: number, val: number) -> ();
	readDouble: (self: object, offset: number) -> number;
	writeDouble: (self: object, offset: number, val: number) -> ();
	swapBytes: (self: object, offsetI: number, offsetJ: number) -> ();

	__len: (self: object) -> number;
	len: (self: object) -> number;
	__tostring: (self: object) -> string;
	toString: (self: object, sType: number?) -> string;
	readi8: (self: object, offset: number) -> number;
	readu8: (self: object, offset: number) -> number;
	readi16: (self: object, offset: number) -> number;
	readu16: (self: object, offset: number) -> number;
	readi32: (self: object, offset: number) -> number;
	readu32: (self: object, offset: number) -> number;
	readf32: (self: object, offset: number) -> number;
	readf64: (self: object, offset: number) -> number;
	writei8: (self: object, offset: number, val: number) -> ();
	writeu8: (self: object, offset: number, val: number) -> ();
	writei16: (self: object, offset: number, val: number) -> ();
	writeu16: (self: object, offset: number, val: number) -> ();
	writei32: (self: object, offset: number, val: number) -> ();
	writeu32: (self: object, offset: number, val: number) -> ();
	writef32: (self: object, offset: number, val: number) -> ();
	writef64: (self: object, offset: number, val: number) -> ();
	readstring: (self: object, offset: number, len: number) -> string;
	writestring: (self: object, offset: number, val: string, count: number?) -> ();
	copy: (self: object, fromOffset: number, to: buffer | object, toOffset: number?, 
		count: number?) -> ();
	fill: (self: object, offset: number, val: number, count: number?) -> ();
}

--// MAIN
local LuaUTypes = require(Objects.LuaUTypes)
local Dash = require(Objects["@CHL/DashSingular"])
local Radix = require(Objects["@CHL/Radix"])
local Iterator = require(Objects["@CHL/Iterator"])
local Class = require(Objects.Class)

module = {}
from = {}
raw_constructors = {}
disguise = LuaUTypes.disguise
compose = Dash.compose
hexUpper = Radix.charRadix.hexdecUpper
readu8 = buffer.readu8
len = buffer.len

function raw_constructors.bytes(...: number): buffer
	local n = select('#', ...)
	local b = buffer.create(n)
	for i = 1, n do
		local byte = select(i, ...)
		buffer.writeu8(b, i - 1, byte)
	end
	
	return b
end

function from.string(s: string): object return module.new(buffer.fromstring(s))end
function from.size(n: number): object return module.new(buffer.create(n))end

function module.new(b: buffer)
	local self: object = disguise(setmetatable({}, module))
	self.referral = b

	return self
end

function enqueReferral(self: object, ...)return self.referral, ... end

function module.swapBytes(self: object, i: number, j: number)
	local t = self:readu8(i)
	self:writeu8(i, self:readu8(j))
	self:writeu8(j, t)
end

function module.writeBytes(self: object, offset: number, ...: number)
	for i = 1, select('#', ...) do
		local b = select(i, ...)
		self:writeu8(offset + i - 1, b)
	end
end

function module.getBytes(self: object, offset: number, len: number)
	len = len or 1

	local result = {}

	for i = 1, len do
		table.insert(result, self:readu8(offset + i - 1))
	end

	return result
end

function module.toString(self: object, sType: number?)
	if not sType then return buffer.tostring(self.referral) end

	if sType == 1 then
		local bytes = self:getBytes(0, self:len())

		for i = 1, #bytes do
			bytes[i] = hexUpper:formatSequence(bytes[i], 2)
		end

		return table.concat(bytes, '_')
	else error(`Bad sType: {sType}`)end
end

function module.copy(self: object, fromOffset: number, to: buffer | object, 
	toOffset: number?, count: number?)
	if typeof(to) == 'buffer' then
		return buffer.copy(self.referral, fromOffset, to, toOffset, count)
	end

	return self:copy(fromOffset, to.referral, toOffset, count)
end

module.readi8 = compose(enqueReferral, buffer.readi8)
module.readu8 = compose(enqueReferral, readu8)
module.readi16 = compose(enqueReferral, buffer.readi16)
module.readu16 = compose(enqueReferral, buffer.readu16)
module.readi32 = compose(enqueReferral, buffer.readi32)
module.readu32 = compose(enqueReferral, buffer.readu32)
module.readf32 = compose(enqueReferral, buffer.readf32)
module.readf64 = compose(enqueReferral, buffer.readf64)
module.writei8 = compose(enqueReferral, buffer.writei8)
module.writeu8 = compose(enqueReferral, buffer.writeu8)
module.writei16 = compose(enqueReferral, buffer.writei16)
module.writeu16 = compose(enqueReferral, buffer.writeu16)
module.writei32 = compose(enqueReferral, buffer.writei32)
module.writeu32 = compose(enqueReferral, buffer.writeu32)
module.writef32 = compose(enqueReferral, buffer.writef32)
module.writef64 = compose(enqueReferral, buffer.writef64)
module.readstring = compose(enqueReferral, buffer.readstring)
module.writestring = compose(enqueReferral, buffer.writestring)
module.fill = compose(enqueReferral, buffer.fill)
module.len = compose(enqueReferral, len)
module.__tostring = module.toString
module.__len = module.len
module.readFloat = module.readf32
module.writeFloat = module.writef32
module.readDouble = module.readf64
module.writeDouble = module.writef64
module.from = from
module.raw_constructors = raw_constructors

Class.makeProperClass(module, '@CHL/BufferWrapper')

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

export type iterator = {
	referral: buffer;
	current: number;
} & Class.subclass<Iterator.object<number>>

BufferIterator = {}

function BufferIterator.init_simple(b: buffer)
	return BufferIterator.simple, b, -1
end

function BufferIterator.simple(b: buffer, current: number)
	current += 1
	if current >= len(b)then return;end
	return current, readu8(b, current)
end

function BufferIterator.new(_buffer: buffer, _current: number?)
	local self: iterator = Class.inherit(Iterator.new(), BufferIterator)
	self.referral = _buffer
	self.current = _current or 0
	
	return self
end

function BufferIterator.canProceed(self: iterator)
	return len(self.referral) > self.current
end

function BufferIterator.proceed(self: iterator)
	local byte = readu8(self.referral, self.current)
	self.current += 1
	return byte
end

Class.makeProperClass(BufferIterator, '@CHL/BufferWrapper/Iterator')
module.BufferIterator = BufferIterator

return module
