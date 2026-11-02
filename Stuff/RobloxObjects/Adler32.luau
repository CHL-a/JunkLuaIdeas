--[[
	From https://en.wikipedia.org/wiki/Adler-32#Example_implementation
	
	some modifications can make it work iteratively
]]

local module = {}

band = bit32.band
rshift = bit32.rshift
bor = bit32.bor
lshift = bit32.lshift
pre_ushort_prime = 65521

function module.iterate(byte: number, crc: number): number
	crc = crc or 1
	
	local ushort_1 = band(crc, 0xFFFF)
	local ushort_2 = rshift(crc, 16)
	
	ushort_1 = (ushort_1 + byte) % pre_ushort_prime
	ushort_2 = (ushort_2 + ushort_1) % pre_ushort_prime
	
	return bor(lshift(ushort_2, 16), ushort_1)
end

return module
