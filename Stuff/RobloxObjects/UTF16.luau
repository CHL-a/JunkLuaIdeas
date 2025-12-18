--[[
	Sources: https://en.wikipedia.org/wiki/UTF-16#U+0000_to_U+D7FF_and_U+E000_to_U+FFFF
]]

local Bit32Ext = require('./@CHL>Bit32Ext')

local module = {}

band = bit32.band
rshift = bit32.rshift
bor = bit32.bor
lshift = bit32.lshift

--#####################################################################################
--#####################################################################################
--#####################################################################################

SurrogatePair = {}

SurrogatePair.short_max = 0xFFFF
SurrogatePair.short_max_above = SurrogatePair.short_max + 1

-- returns if codepoint is or can be paired, or not
function SurrogatePair.is_paired_from_codepoint(codepoint: number): boolean
	return codepoint >= 0x010000
end

SurrogatePair.surrogate_mask = 0xD800
SurrogatePair.surrogate_type_mask = 0x0400

-- checks if ushort is a surrogate, returns specific type
function SurrogatePair.get_type(ushort: number): 'high' | 'low' | 'not'
	if band(ushort, SurrogatePair.surrogate_mask) ~= SurrogatePair.surrogate_mask then
		return 'not'
	end

	if not Bit32Ext.flag_test(ushort, SurrogatePair.surrogate_type_mask) then
		return 'high'
	else
		return 'low'
	end
end

SurrogatePair.mask_10_bits_right = 0x03FF

-- returns a high and low surrogate pair
function SurrogatePair.from_codepoint(codepoint: number): (number, number)
	assert(SurrogatePair.is_paired_from_codepoint(codepoint), `codepoint {codepoint} is not pairable`)

	codepoint -= SurrogatePair.short_max_above

	local low_value = band(codepoint, SurrogatePair.mask_10_bits_right)
	local high_value = rshift(codepoint, 10)

	return bor(SurrogatePair.surrogate_mask, high_value),
		bor(SurrogatePair.surrogate_mask, SurrogatePair.surrogate_type_mask, low_value)
end

function SurrogatePair.to_codepoint(high: number, low: number): number
	assert(SurrogatePair.get_type(high) == 'high')
	assert(SurrogatePair.get_type(low) == 'low')

	local high_value = band(high, SurrogatePair.mask_10_bits_right)
	local low_value = band(low, SurrogatePair.mask_10_bits_right)

	return bor(low_value, lshift(high_value, 10)) + SurrogatePair.short_max_above
end

module.surrogate_pair = SurrogatePair

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Iterator = require('./@CHL>Iterator')
local UTF8Ext = require('./@CHL>UTF8Ext')
local Object = require('./Object')
local Class = require('./Class')
local Dash = require('./@CHL>DashSingular')

export type surrogate_iterator = {
	codepoint_iterator: UTF8Ext.codepoint_iterator;
	cached_short: number?
} & Iterator.simple<number>

-- an iterator of numbers, returns a short, transforms utf8 (based on luau) to utf16
SurrogatePairIterator = {}
compose = Dash.compose

function SurrogatePairIterator.new(cp_it: UTF8Ext.codepoint_iterator): surrogate_iterator
	local self: surrogate_iterator = Object.simple.new(SurrogatePairIterator)
	self.codepoint_iterator = cp_it
	return self
end

function SurrogatePairIterator.can_proceed(self: surrogate_iterator): boolean
	return self.codepoint_iterator:can_proceed() or self.cached_short
end

function SurrogatePairIterator.proceed(self: surrogate_iterator): number
	if not self:can_proceed() then return;end
	local result;
	
	if self.cached_short then
		result = self.cached_short
		self.cached_short = nil
	else
		result = self.codepoint_iterator:proceed()
		
		if SurrogatePair.is_paired_from_codepoint(result) then
			local high, low = SurrogatePair.from_codepoint(result)
			
			result = high
			self.cached_short = low
		end
	end
	
	return result
end

SurrogatePairIterator.from = {}
SurrogatePairIterator.from.string = compose(UTF8Ext.iterator.codepoint.from.string, SurrogatePairIterator.new) :: (s: string) -> (surrogate_iterator)

Iterator.simple.declare_as(SurrogatePairIterator)

Class.makeProperClass(SurrogatePairIterator, '@CHL>UTF16>Surrogate>Iterator>Forward')

SurrogatePair.iterator = SurrogatePairIterator

--#####################################################################################
--#####################################################################################
--#####################################################################################

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
