--// TYPES
local Objects = script.Parent
local Map = require(Objects["@CHL/Map"]) 

export type digitsMap<A> = Map.simple<A, number>

export type object<A> = {
	digits: {A};
	digitsMap: digitsMap<A>;
	
	toDecimal: (self: object<A>, {A}) -> number;
	fromDecimal: (self: object<A>, number) -> {A};
}

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)
module.__index = module

disguise = LuaUTypes.disguise

function create<A>(digits: {A}, dMap: digitsMap<A>): object<A>
	local self: object<A> = disguise(setmetatable({}, module))
	
	self.digits = digits
	self.digitsMap = dMap
	
	return self
end

from = {}

function fromArray<A>(digits: {A}): object<A>
	local map = Map.simple.flipArray(digits)
	
	for i in next, map do
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
	for i in next, map do
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
module.toDecimal = function<A>(self: object<A>, sequence: {A})
	local result = 0
	local base = #self.digits
	local map = self.digitsMap
	local m = #sequence
	
	for i, v in next, sequence do
		local mult = assert(map[v], `Attempting to use a non-digit: {v}`)
		result += mult * base ^ (m - i)
	end
	
	return result
end

module.fromDecimal = function<A>(self: object<A>, n: number)
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

--######################################################################################
--######################################################################################
--######################################################################################

local Class = require(Objects.Class) 

export type charRadix = {
	toDecimal: (self: charRadix, seq: string) -> number;
	fromDecimal: (self: charRadix, number) -> string;
} & Class.subclass<object<string>>

charRadix = {}
charRadix.__index = charRadix

function charRadix.new(s:string): charRadix
	return Class.inherit(fromChars(s), charRadix)
end

charRadix.toDecimal = function(self: charRadix, seq: string)
	return self.__super:toDecimal(seq:split'')
end

charRadix.fromDecimal = function(self: charRadix, n: number)
	return table.concat(self.__super:fromDecimal(n))
end

charRadix.binary = charRadix.new'01'
charRadix.hexdecLower = charRadix.new'0123456789abcdef'
charRadix.hexdecUpper = charRadix.new'0123456789ABCDEF'

module.charRadix = charRadix

return module
