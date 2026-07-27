--// TYPES
local Map = require('./@CHL>Map') 
local Object = require('./Object')
local Class = require('./Class')
local Dash = require('./@roblox>Dash')

export type digits_map<A> = Map.simple<A, number>

export type object<A> = {
	digits: {A};
	digits_map: digits_map<A>;
	
	to_number: (self: object<A>, {A}) -> number;
	from_number: (self: object<A>, number) -> {A};
}

--// MAIN
local module = {}
local LuaUTypes = require('./LuaUTypes')
local base = {}

disguise = LuaUTypes.disguise
compose = Dash.compose

function base.new<A>(digits: {A}, dMap: digits_map<A>): object<A>
	local self: object<A> = Object.simple.new(module)
		
	self.digits = digits
	self.digits_map = dMap
	
	return self
end

base.from = {}

function base.from.map<A>(map: digits_map<A>): object<A>
	local array = {}
	
	for i, v in next, map do
		array[v + 1] = i
	end
	
	return base.new(array, map)
end

function base.from.one_based_array<A>(map: digits_map<A>): object<A>
	for i in map do
		map[i] -= 1
	end
	
	return base.from.map(map)
end

base.from.array = compose(Map.simple.flip_array, base.from.one_based_array) :: <A>(digits: {A}) -> object<A>
base.from.chars = compose(string.split, base.from.array) :: (char_set: string) -> object<string>

--[[
<--- increases by base
ABCDEF
--]]

function base.to_number<A>(self: object<A>, sequence: {A})
	local result = 0
	local base = #self.digits
	local map = self.digits_map
	local m = #sequence
	
	for i, v in sequence do
		local mult = assert(map[v], `Attempting to use a non-digit: {v}`)
		result += mult * base ^ (m - i)
	end
	
	return result
end

function base.from_number<A>(self: object<A>, n: number)
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

Class.make_proper_class(base, '@CHL>Radix>Base')

module.base = base

--######################################################################################
--######################################################################################
--######################################################################################

export type char_radix = {
	to_number: (self: char_radix, seq: string) -> number;
	from_number: (self: char_radix, number) -> string;
	format_sequence: (self: char_radix, n: number, maxLength: number?) -> string;
} & object<string>

char_radix = {}

function char_radix.new(s:string): char_radix
	return setmetatable(base.from.chars(s), char_radix) -- subject to be changed
end

function char_radix.to_number(self: char_radix, seq: string)
	return base.to_number(self, seq:split'')
end

function char_radix.from_number(self: char_radix, n: number)
	return table.concat(base.from_number(self, n))
end

Class.make_proper_class(char_radix, '@CHL>Radix>Char')
Class.simple.assign_sub_class(base, char_radix)

--######################################################################################
--######################################################################################
--######################################################################################

local binary = char_radix.new'01'

function binary.format_sequence(self: char_radix, n: number, len: number?)
	local result = ''
	local seq = self:fromDecimal(n)
	
	if len then
		result ..= ('0'):rep(len - #seq)
	end
	
	result ..= seq
	
	return result
end

local hexlower = char_radix.new'0123456789abcdef'

function hexlower.format_sequence(self: char_radix, n: number, len: number?)
	local result = ''
	local seq = self:fromDecimal(n)

	if len then
		result ..= ('0'):rep(len - #seq)
	end

	result ..= seq

	return result
end

local hexupper = char_radix.new'0123456789ABCDEF'
hexupper.formatSequence = hexlower.formatSequence

local alphanumeric = char_radix.new'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

binary.class_name = '@CHL>Radix>Char>Binary'
hexlower.class_name = '@CHL>Radix>Char>HexLower'
hexupper.class_name = '@CHL>Radix>Char>HexUpper'
alphanumeric.class_name = '@CHL>Radix>Char>Alphanumeric'

char_radix.binary = binary
char_radix.hex_lower = hexlower
char_radix.hex_upper = hexupper
char_radix.alphanumeric = alphanumeric

module.char_radix = char_radix

return module
