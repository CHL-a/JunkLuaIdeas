--// TYPES
local Objects = script.Parent
local Radix = require(Objects["@CHL/Radix"])
local ByteStream = require(Objects["@CHL/ByteStream"])
local Map = require(Objects["@CHL/Map"])

type map<i, v> = Map.simple<i, v>

export type object = {
	padding: string;
	debugBytes: {number};
	stream: ByteStream.object;
	digits: {string};
	digitMap: map<string, number>;
	
	get: (self: object, number?) -> string;
	encode: (self: object, input: string) -> string;
	decode: (self: object, input: string) -> string;
}

--// MAIN
local Base64 = {}
local LuaUTypes = require(Objects.LuaUTypes)
local Math = require(Objects.Math)
local TableUtils = require(Objects["@CHL/TableUtils"])

binary = Radix.charRadix.binary
push = TableUtils.push
getDigit = Math.getDigit
disguise = LuaUTypes.disguise

Base64.defaultPadding = '='
Base64.digits = {}
Base64.__index = Base64;

function addDigits(s: string)
	for i = s:byte(1), s:byte(2)do
		push(Base64.digits, string.char(i))
	end
end

function printBytes(n: {number})
	local s = ''
	
	for i = 1, #n do
		local seq = Radix.charRadix.hexdecUpper:fromDecimal(n[i])
		
		if #seq == 1 then
			s ..= '0'
		end
		
		s..= seq
	end
	
	local s2 = '0b'
	
	for i = 1, #s do
		local c = s:sub(i,i)
		local seq = Radix.charRadix.binary:fromDecimal(
			Radix.charRadix.hexdecUpper:toDecimal(c)
		)
		
		s2 ..= `{('0'):rep(4 - #seq)}{seq}_`
	end
	print(s2)
end

function create(
	digitMap, 
	digits: {string}, 
	padding: string?): object
	
	local self: object = disguise(setmetatable({}, Base64))
	
	self.padding = padding or Base64.defaultPadding
	self.debugBytes = {}
	self.stream = ByteStream.from.array(self.debugBytes)
	self.digits = digits
	self.digitMap = digitMap
	
	return self
end

function Base64.get(self: object, n: number)
	local i = self.stream:getBits(n or 6) + 1
	
	return self.digits[i]
end

function Base64.encode(self: object, s: string)
	-- pre
	assert(type(s) == 'string')

	-- main
	local result = ''
	
	local stream = self.stream
	
	-- input to stream
	for i = 1, #s do
		stream:appendBytes(s:byte(i))
	end

	-- extract from stream and construct from result
	-- implementation varies

	-- start with an iteration per 3 characters
	for i = 1, (#s // 3) do
		for i = 1, 4 do
			result ..= self:get()
		end
	end
	
	-- any remaining characters should be managed by padding
	if #s % 3 ~= 0 then
		local r = #s % 3
		
		for i = 1, r do
			result ..= self:get()
		end
		
		local a = stream:getBits((r * 2)) * 2 ^ (6 - r * 2) + 1
		
		result ..= self.digits[a]
		
		-- add padding
		result ..= self.padding:rep(3 - r)
	end

	return result
end

function Base64.decode(self: object, s: string)
	-- pre
	assert(type(s) == 'string')
	assert(#s % 4 == 0, 'missing padding')

	-- main
	local result = ''
	local padding = self.padding
	local stream = self.stream
	local sects = #s / 4
	
	-- insert to stream
	for a = 1, sects do -- per set

		-- insert 4 char set
		for b = 1, 4 do
			b += (a - 1) * 4
			local c = s:sub(b, b)

			if c == padding then continue end
			
			local d = self.digitMap[c] - 1
			
			for i = 5, 0, -1 do
				local di = getDigit(d, 2, i)
				--print(c, d, i, di)
				stream:appendBits(di)
			end
		end

		-- concat with 3 characters out
		
		if a ~= sects then
			result ..= stream:getString(3)
		end
	end
	
	--printBytes(self.debugBytes)
	
	-- anything better?
	local paddingLen = 
		s:sub(-2) == padding:rep(2) and 2
		or s:sub(-1) == padding and 1
		or 0
	
	result ..= stream:getString(3 - paddingLen)
	
	if paddingLen ~= 0 then
		-- empty stream
		for _ = 1, 8 - 2 ^ paddingLen do
			stream:appendBits(0)
		end

		stream:getString()
	end
	
	return result
end

function Base64.new(digits: {string}?, padding: string?): object
	local d = digits or Base64.digits
	local map = Map.simple.flipArray(d)
	
	return create(map, d, padding or Base64.defaultPadding)
end

addDigits'AZ'
addDigits'az'
addDigits'09'
push(Base64.digits, '+', '/')
Base64.default = Base64.new()

return Base64
