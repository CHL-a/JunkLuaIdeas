local module = {}
local Bit32Ext = require('./@CHL>Bit32Ext')

lshift = bit32.lshift
band = bit32.band
rshift = bit32.rshift
bnot = bit32.bnot
bxor = bit32.bxor
bor = bit32.bor

module.range_mask = 0xFF
module.range_complement = bnot(module.range_mask)

-- given a number, it clamps bits to a byte range, can have offset a number based on the amount of 0s
function module.bit_clamp(byte: number, offset: number?)
	local o = offset or 0
	return rshift(band(lshift(byte, o), module.range_mask), o)
end

-- given a number, it returns whether a number is in byte range
function module.is_in_range(number)
	return band(number, module.range_complement) == 0x00
end

-- given number, it returns two numbers given a slice
function module.slice(byte: number, slice_from_left: number): (number, number)
	return rshift(byte, 8-slice_from_left), 
		module.bit_clamp(byte, slice_from_left)
end

-- returns bits swapped mask (swap mask has at least two bits)
function module.bit_swap_mask(byte: number, swap_mask: number)
	assert(Bit32Ext.bit_count(swap_mask) == 2)
	
	byte = band(byte, swap_mask)
	
	if byte == 0x00 or byte == swap_mask then
		return byte
	else
		return band(swap_mask, bnot(byte))
	end
end

-- directly bit swaps
function module.bit_swap(byte: number, ...:number)
	local len = select('#', ...)
	
	for i = 1, len do
		local mask = select(i, ...)
		
		byte = bor(
			band(byte, bnot(mask)),
			module.bit_swap_mask(byte, mask)
		)
	end
	
	return byte
end

function module.reverse(byte: number)
	return 
		module.bit_swap(
			byte, 
			0b_1000_0001,
			0b_0100_0010,
			0b_0010_0100,
			0b_0001_1000
		)
end

return module
