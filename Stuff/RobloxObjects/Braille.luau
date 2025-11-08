--[[
	responsible for managing braile as bytes

	Bit formats:
	
	[87654321]
	
	Standard:|Row first:|column first:|
	14       |12        |15           |
	25       |34        |26           |
	36       |56        |37           |
	78       |78        |48           |
	
	All bit formats are in standard unless stated otherwise
]]


local Byte = require('./@CHL>Byte')
local Dash = require('./@CHL>DashSingular')

local module = {}

band = bit32.band
rshift = bit32.rshift
bnot = bit32.bnot
bswap = Byte.bit_swap
bor = bit32.bor

function multi_bit_swap(list, is_reversed: boolean?)
	if is_reversed then
		list = Dash.reverse(list)
	end
	return function(std: number): number
		return Byte.bit_swap(std, unpack(list))
	end
end

function module.is_braille(codepoint: number): boolean
	return band(codepoint, Byte.range_complement) == module.base
end

module.to = {}
module.from = {}

module.base = 0x2800
module.base_complement = bnot(module.base)

module.row_first_swaps = {
	0b0000_1010,
	0b0001_1000,
	0b0001_0100
}
module.column_first_swaps = {
	0b0100_1000,
	0b0001_1000,
	0b0011_0000
}

module.to.row_first = multi_bit_swap(module.row_first_swaps)
module.to.column_first = multi_bit_swap(module.column_first_swaps)
module.from.row_first = multi_bit_swap(module.row_first_swaps, true)
module.from.column_first = multi_bit_swap(module.column_first_swaps, true)


return module
