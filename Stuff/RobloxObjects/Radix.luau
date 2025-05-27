--// TYPES
local Map = require('./@CHL>Map') 
local Object = require('./Object')
local Class = require('./Class')

export type digitsMap<A> = Map.simple<A, number>

export type object<A> = {
	digits: {A};
	digitsMap: digitsMap<A>;
	
	toDecimal: (self: object<A>, {A}) -> number;
	fromDecimal: (self: object<A>, number) -> {A};
} & Object.object_inheritance

--// MAIN
local module = {}
local LuaUTypes = require('./LuaUTypes')


disguise = LuaUTypes.disguise

function create<A>(digits: {A}, dMap: digitsMap<A>): object<A>
	local self: object<A> = Object.from.class(module)
		
	self.digits = digits
	self.digitsMap = dMap
	
	return self
end

from = {}

function fromArray<A>(digits: {A}): object<A>
	local map = Map.simple.flipArray(digits)
	
	for i in map do
		map[i] -= 1
	end
	
	return create(digits, map)
end

-- uses 0based map
function fromMap<A>(map: digitsMap<A>): object<A>
	local array = {}
	
	for i, v in next, map do
		array[v + 1] = i
	end
	
	return create(array, map)
end

function fromOneBasedMap<A>(map: digitsMap<A>): object<A>
	for i in map do
		map[i] -= 1
	end
	
	return fromMap(map)
end

function fromChars(s: string): object<string>return fromArray(s:split'')end

from.array = fromArray
from.map = fromMap
from.oneBasedMap = fromOneBasedMap
from.chars = fromChars;
module.from = from

--[[
<--- increases by base
ABCDEF
--]]

function module.toDecimal<A>(self: object<A>, sequence: {A})
	local result = 0
	local base = #self.digits
	local map = self.digitsMap
	local m = #sequence
	
	for i, v in sequence do
		local mult = assert(map[v], `Attempting to use a non-digit: {v}`)
		result += mult * base ^ (m - i)
	end
	
	return result
end

function module.fromDecimal<A>(self: object<A>, n: number)
	local result = {}
	local base = #self.digits
	local digits = 1 + math.log(math.max(1, n), base) // 1
	
	for i = digits - 1, 0, -1 do
		local b = base ^ i
		local mult = n // b
		
		table.insert(result, self.digits[mult + 1])
		
		n %= b
	end
	
	return result
end

Class.makeProperClass(module, '@CHL>Radix')

--######################################################################################
--######################################################################################
--######################################################################################

export type charRadix = {
	toDecimal: (self: charRadix, seq: string) -> number;
	fromDecimal: (self: charRadix, number) -> string;
	formatSequence: (self: charRadix, n: number, maxLength: number?) -> string;
} & Class.subclass<object<string>>

charRadix = {}

function charRadix.new(s:string): charRadix
	return fromChars(s):__inherit(charRadix)
end

function charRadix.toDecimal(self: charRadix, seq: string)
	return self.__super:toDecimal(seq:split'')
end

function charRadix.fromDecimal(self: charRadix, n: number)
	return table.concat(self.__super:fromDecimal(n))
end

Class.makeProperClass(charRadix, '@CHL>Radix>Char')

local binary = charRadix.new'01'

function binary.formatSequence(self: charRadix, n: number, len: number?)
	local result = ''
	local seq = self:fromDecimal(n)
	
	if len then
		result ..= ('0'):rep(len - #seq)
	end
	
	result ..= seq
	
	return result
end

local hexlower = charRadix.new'0123456789abcdef'

function hexlower.formatSequence(self: charRadix, n: number, len: number?)
	local result = ''
	local seq = self:fromDecimal(n)

	if len then
		result ..= ('0'):rep(len - #seq)
	end

	result ..= seq

	return result
end

local hexupper = charRadix.new'0123456789ABCDEF'
hexupper.formatSequence = hexlower.formatSequence

binary.className = '@CHL>Radix>Char>Binary'
hexlower.className = '@CHL>Radix>Char>HexLower'
hexupper.className = '@CHL>Radix>Char>HexUpper'

charRadix.binary = binary
charRadix.hexdecLower = hexlower
charRadix.hexdecUpper = hexupper

module.charRadix = charRadix

return module
