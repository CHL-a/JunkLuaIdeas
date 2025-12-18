local Iterator = require('./@CHL>Iterator')
local Byte = require('./@CHL>Byte')

export type byte_iterator = Iterator.simple<number>

local module = {}

band = bit32.band
lshift = bit32.lshift
bor = bit32.bor
y_clamp = Byte.bit_clamp
bnot = bit32.bnot

module.size_masks = {
	{
		mask1 = 0b1000_0000;
		mask2 = 0b0000_0000;
		size  = 1
	},
	{
		mask1 = 0b1110_0000;
		mask2 = 0b1100_0000;
		size  = 2
	},
	{
		mask1 = 0b1111_0000;
		mask2 = 0b1110_0000;
		size  = 3
	},
	{
		mask1 = 0b1111_1000;
		mask2 = 0b1111_0000;
		size  = 4
	},
}

-- returns size of chunk based on first byte
function module.get_size(first_byte): number?
	for _, v in module.size_masks do
		if band(first_byte, v.mask1) == v.mask2 then
			return v.size
		end
	end
	
	return
end

export type parse_result = {
	is_valid_codepoint: boolean;
	bytes: {number};
	codepoint: number;
	message: string;
}

--[[
	Uses byte iterator to return a parse struct
]]
function module.parse(byte_it: byte_iterator): parse_result
	local result: parse_result = {
		is_valid_codepoint = false;
		bytes = {};
		codepoint = 0;
		message = 'no message'
	}
	
	if not byte_it:can_proceed() then
		result.message = 'byte iterator non proceedable'
		return result;
	end
	
	local first = byte_it:proceed()
	local size = module.get_size(first)
	local bytes = result.bytes
	
	table.insert(bytes, first)
	
	if not size then
		result.message = `bad first byte: failed to get size: {first}`
		return result
	end
	
	-- anything else to the right of mask1 is considered part of code point
	result.codepoint = band(first, y_clamp(bnot(module.size_masks[size].mask1)))
	
	for i = 2, size do
		if not byte_it:can_proceed() then
			result.message = 'byte iterator non proceedable while in size loop'
			return result
		end
		
		local current = byte_it:proceed()
		
		table.insert(result.bytes, current)
		
		if band(current, 0b1100_0000) ~= 0b1000_0000 then
			result.message = 'malformed utf8 sequence'
			return result
		end
		
		result.codepoint = bor(
			lshift(result.codepoint, 6),
			band(current, 0b0011_1111)
		)
	end
	
	result.is_valid_codepoint = true
	
	return result
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

local StringUtils = require('./@CHL>StringUtils')
local Object = require('./Object')
local Class = require('./Class')
local Dash = require('./@CHL>DashSingular')

type s_iterator<T, U...> = Iterator.simple<T, U...>

export type codepoint_iterator = {
	byte_it: byte_iterator;
	parse_struct: parse_result;
} & s_iterator<number>

codepoint_iterator = {}
compose = Dash.compose

function codepoint_iterator.new(byte_it: byte_iterator): codepoint_iterator
	local self: codepoint_iterator = Object.simple.new(codepoint_iterator)
	
	self.byte_it = byte_it
	
	return self
end

function codepoint_iterator.can_proceed(self: codepoint_iterator)
	return self.byte_it:can_proceed()
end

function codepoint_iterator.proceed(self: codepoint_iterator)
	if not self:can_proceed() then return end
	
	local struct = module.parse(self.byte_it)
	
	self.parse_struct = struct
	
	if not struct.is_valid_codepoint then
		return
	end
	
	return struct.codepoint
end

codepoint_iterator.from = {}
codepoint_iterator.from.string = compose(StringUtils.iterator.byte.new, codepoint_iterator.new) :: (string)->codepoint_iterator

codepoint_iterator.__iter = Iterator.simple.__iter
Class.makeProperClass(codepoint_iterator, '@CHL>UTF8Ext>Iterator>Codepoint')
module.iterator = {}
module.iterator.codepoint = codepoint_iterator

--#########################################################################################
--#########################################################################################
--#########################################################################################

export type char_iterator = {
	cp_it: codepoint_iterator;
} & s_iterator<string>

char_iterator = {}

function char_iterator.new(cp_it:codepoint_iterator): char_iterator
	local self: char_iterator = Object.simple.new(char_iterator)

	self.cp_it = cp_it

	return self
end

function char_iterator.can_proceed(self: char_iterator)
	return self.cp_it:can_proceed()
end

function char_iterator.proceed(self: char_iterator)
	if not self:can_proceed() then return end

	local codepoint = self.cp_it:proceed()
	
	if not codepoint then
		return
	end
	
	return utf8.char(codepoint)
end

char_iterator.from = {}
char_iterator.from.string = compose(codepoint_iterator.from.string, char_iterator.new)
char_iterator.__iter = Iterator.simple.__iter
Class.makeProperClass(char_iterator, '@CHL>UTF8Ext>Iterator>Char')
module.iterator.char = char_iterator

--#########################################################################################
--#########################################################################################
--#########################################################################################

module.default_library = utf8

return module
