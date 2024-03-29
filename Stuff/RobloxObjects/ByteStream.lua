--[[
	Lua replication of a byte stream
	Note: 
	
	Most sigificant bit
	 v
	+--------+
	|12345678| <- this box represents a collection of 8 bits or one byte
	+--------+
	        ^
	Least Sigificant bit
	
	 * numbers indicate bit position not an actual possible bit value
--]]

--// TYPES
local Objects = script.Parent
local Class = require(Objects.Class)
local Stream = require(Objects["@CHL/Stream"])
local TableUtils = require(Objects["@CHL/TableUtils"])

export type object = {
	-- get
	bitPointer: number;
	bytePointer: number;

	increment: (self: object, dir: number?) -> nil;
	
	getLine: (self: object) -> string;
	getDouble: (self: object, isLilend: boolean) -> number;
	getBits: (self: object, n: number?) -> number;
	getBytes: (self: object, n: number?) -> number;
	getString: (self: object, n: number?) -> string;
	getFloat: (self: object, isLilEnd: boolean?) -> number;
	getAllRemainingContent: (self: object) -> string;
	
	-- given n, in bytes, returns a signed int
	getSignedInt: (self: object, n: number) -> number;
	
	isBitOne: (self: object) -> boolean;
	checkBytes: (self: object,...number) -> true | number;
	assertBytes: (self: object,eMsg: string?, ...number) -> nil;

	peekByte: (self: object,number?) -> number;

	-- append
	appendingBitPosition: number;
	appendingByte: number;

	appendBits: (self: object,... number?) -> object;
	appendBytes: (self: object,... number?) -> object;
	
	appendSignedInt: (self: object, n: number, bytes: number, isLilEnd: boolean?) -> object;
	appendDouble: (self: object, n: number, isLilEnd: boolean?) -> object;
	appendInt: (self: object,n: number, isLilEnd: boolean?) -> object;
	appendFloat: (self: object,n: number, isLilend: boolean?) -> object;
	appendString: (self: object, ...string) -> object;

	-- cond
	atEnd: (self: object) -> boolean;
} & Class.subclass<Stream.object<number>>

--// MAIN
local ByteStream = {}
local Dash = require(Objects["@CHL/DashSingular"])
local LuaUTypes = require(Objects.LuaUTypes)
local Math = require(Objects.Math)
local BufferWrapper = require(Objects["@CHL/BufferWrapper"])

tempBuffer = BufferWrapper.getTemp()
getDigit = Math.getDigit
disguise = LuaUTypes.disguise
lineBreakByte = ('\n'):byte()
from = {}

function ByteStream.new(getF, appendF): object
	local self: object = Class.inherit(Stream.new(getF, appendF), ByteStream)

	-- getting
	self.bitPointer = 1
	self.bytePointer = 1
	
	-- appending
	self.appendingBitPosition = 1;
	self.appendingByte = 0;

	return self
end

-- append bytestream with n of length bytes
ByteStream.appendSignedInt = function(
	self: object, 
	n: number,
	bytes: number,
	isLilEnd: boolean?)
	
	tempBuffer[`writei{bytes*8}`](tempBuffer, 0, n)
	
	for i = 1, bytes do
		self:appendBytes(
			tempBuffer:readu8(isLilEnd and i - 1 or bytes - i)
		)
	end
end

-- given n, in bytes, returns a signed int
ByteStream.getSignedInt = function(self: object, n: number)
	for i = 1, math.abs(n) do
		tempBuffer:writeu8(n < 0 and i - 1 or 4 - i, self:getBytes())
	end
	
	return tempBuffer[`readi{n*8}`](tempBuffer, 0)
end

ByteStream.getLine = function(self: object)
	local i = 1
	
	while self:peekByte(i) ~= lineBreakByte and self:atEnd() do
		i += 1;
	end
	
	if self:atEnd() then
		return self:getAllRemainingContent()
	end
	local result = self:getString(i-1)
	
	self:getBytes()
	
	return result
end

ByteStream.getDouble = function(self: object, isLilend: boolean)
	for i = 0, 7 do
		tempBuffer:writeu8(i, self:getBytes())
	end

	if not isLilend then
		for i = 0, 3 do
			tempBuffer:swapBytes(i, 7 - i)
		end
	end

	return tempBuffer:readDouble(0)
end

ByteStream.appendDouble = function(self: object, n: number, isLilEnd: boolean?)
	tempBuffer:writeDouble(0, n)
	
	if not isLilEnd then
		for i = 0, 3 do
			tempBuffer:swapBytes(i, 7 - i)
		end
	end
	
	for i = 0, 7 do
		self:appendBytes(tempBuffer:readu8(i))
	end
	
	return self
end

ByteStream.getAllRemainingContent = function(self: object)
	local result = ''
	
	while not self:atEnd() do
		result ..= self:getString(1)
	end
	
	return result
end

ByteStream.appendString = function(self: object, ...: string)
	local n = select('#', ...)
	
	for i = 1, n do
		local s:string = select(i, ...)
		
		for j = 1, #s do
			self:appendBytes(s:byte(j))
		end
	end
	
	return self
end

ByteStream.atEnd = function(self: object)return not self:get(self.bytePointer)end

ByteStream.appendFloat = function(self: object, n: number, isLilEnd)
	tempBuffer:writeFloat(0, n)
	
	if not isLilEnd then
		for i = 0, 1 do
			tempBuffer:swapBytes(i, 3 - i)
		end
	end
	
	for i = 0, 3 do
		self:appendBytes(tempBuffer:readu8(i))
	end
	
	-- old
	--[=[
	local m, e = math.frexp(n)
	local sign = math.sign(m) == -1 and 1 or 0

	m = math.ceil((math.abs(m) - .5) * 2 ^ 24)
	e += 126

	local temp = {
		sign * 2 ^ 7 +
		e // 2,

		(e % 2) * (2 ^ 7) + 
		m // (2 ^ 16),

		(m / (2 ^ 8)) % 2 ^ 8,

		m % 2 ^ 8
	}

	if isLilEnd then
		local a, b = unpack(temp, 1, 2)

		temp[1], temp[2] = temp[4], temp[3]
		temp[4], temp[3] = a, b

				--[[
				local a, b, c = temp.getBytes(),
					temp.getBytes(),
					temp.getBytes()
				
				temp.appendBytes(
					temp.getBytes(),
					c, b, a
				)
				--]]
	end

	for i = 1, 4 do self:appendBytes(temp[i])end
	--]=]
	return self
end

ByteStream.appendInt = function(self: object, n, isLilend)
	-- pre
	assert(n % 1 == 0)

	-- main
	for i = 1, 4 do
		self:appendBytes(getDigit(n, 256, isLilend and 4 - i or i - 1))
	end

	return self
end

ByteStream.appendBytes = function (self: object, ...)
	for i = 1, select('#', ...) do
		-- pre
		local n = select(i, ...)
		assert(n % 1 == 0 and n >= 0)


		-- main
		local a = ''
		for i = 7, 0, -1 do
			local b = getDigit(n, 2, i)
			self:appendBits(b)
			a ..= b
		end
	end
	return self
end;

ByteStream.appendBits = function (self: object, ...)
	for i = 1, select('#', ...) do
		-- pre
		local n = select(i, ...)
		assert(n == 1 or n == 0)

		-- main
		self.appendingByte += n * 2 ^ (8 - self.appendingBitPosition)
		self.appendingBitPosition += 1

		if self.appendingBitPosition >= 9 then
			self.appendingBitPosition %= 8
			self:append(self.appendingByte)
			self.appendingByte = 0
		end
	end

	return self
end;

ByteStream.peekByte = function(self: object, n)
	n = n or 1
	return self:get(self.bytePointer + n - 1)
end

ByteStream.getFloat = function(self: object, isLilEnd)
	for i = 0, 3 do
		tempBuffer:writeu8(i, self:getBytes())
	end
	
	if not isLilEnd then
		for i = 0, 1 do
			tempBuffer:swapBytes(i, 3 - i)
		end
	end
	
	-- old
	--[[
	local temp: object = disguise(ByteStream).temp
	local tempA = {}

	for _ = 1, 4 do
		local b = self:getBytes()
		table.insert(tempA, isLilEnd and 1 or #tempA, b)
	end

	for _ = 1, 4 do temp:appendBytes(table.remove(tempA, 1))end

	local a, b, c = temp:isBitOne(), temp:getBytes(), temp:getBits(23)

	local sign = a and -1 or 1
	local exponent = b - (2 ^ 7 - 1)
	local mantissa = c / (2 ^ 23) + 1

	return mantissa * (2 ^ exponent) * sign
	--]]
	return tempBuffer:readFloat(0)
end

ByteStream.assertBytes = function(self: object, e, ...)
	-- pre
	e = e or 'byte check fail:'

	-- main
	local a, b = self:checkBytes(...)

	if a ~= true then
		e ..= '\n'
		local f = ''
		
		for i = 1, select('#', ...) do
			local expByte = select(i, ...)
			e ..= `{expByte} `

			if i == a then
				f ..= `{b}\n{(' '):rep(#f)}^`
				break
			else
				f ..= `{expByte} `
			end
		end

		error(`{e}\n{f}`)
	end
end

ByteStream.checkBytes = function(self: object, ...: number)
	-- main
	local resultA = true
	local resultB

	for i = 1, select('#', ...) do
		local byte = self:getBytes()
		local byteB = select(i, ...)
		
		if byteB ~= byte then
			resultA = i
			resultB = byte
			break
		end
	end

	return resultA, resultB
end

ByteStream.isBitOne = function (self: object)return self:getBits() == 1 end;

ByteStream.getString = function(self: object, len)
	-- pre
	len = len or 1
	assert(len % 1 == 0,  `{typeof(len)}|{len}` )

	-- main
	local result = ''

	for i = 1, math.abs(len) do
		local byte = self:getBytes()

		result ..= string.char(byte)
	end

	if len < 0 then
		result = result:reverse()
	end

	return result
end;

--[[
	Returns an integer, negative n denotes lil endian
--]]
ByteStream.getBytes = function(self:object, n)
	-- pre
	n = n or 1
	assert(type(n) == 'number' and n ~= 0 and n % 1 == 0, tostring(n))

	-- main
	local result

	if n >= 1 then
		-- big endian
		result = self:getBits(n * 8)
	else
		-- little endian
		result = 0

		for byte = 1, -n do
			result += self:getBytes() * 256 ^ (byte - 1)
		end
	end

	return result
end;

ByteStream.increment = function(self: object, dir)
	self.bitPointer += 1

	if self.bitPointer >= 9 then
		self.bitPointer %= 8
		self.bytePointer += dir or 1
	end
end;

ByteStream.getBits = function(self: object, n)
	-- pre
	n = n or 1
	assert(type(n) == 'number', 'not number')
	assert(n >= 1, 'n < 1')
	assert(n % 1 == 0, 'non integer: ' .. n)

	-- main
	local result = 0

	for i = 1, n do
		local byte = self:get(self.bytePointer)
		assert(byte, 'missing byte: reached end of stream')

		result += getDigit(byte, 2, 8 - self.bitPointer) * 2 ^ (n - i)

		self:increment()
	end

	return result
end;

function from.array(array: {number}): object
	return ByteStream.new(
		function(i)return array[i]end,
		function(...: number)TableUtils.push(array, ...)end
	)
end

function from.string(s: string): object
	return ByteStream.new(
		function(i)return s:byte(i)end,
		function(...: number)
			for i = 1, select('#', ...) do
				local b = select(i, ...)
				s ..= string.char(b)
			end
		end
	)
end

ByteStream.from = from
ByteStream.temp = from.array{}
ByteStream.__index = ByteStream

return ByteStream
