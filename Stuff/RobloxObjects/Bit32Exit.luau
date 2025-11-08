-- Extends b32 library

local module = {}

bnot = bit32.bnot
rshift = bit32.rshift
countrz = bit32.countrz
bor = bit32.bor


function module.bit_count(u32: number): number
	local result = 0
	
	while u32 ~= 0 do
		local zero_count = countrz(u32)
		u32 = rshift(u32, zero_count + 1)
		result += 1
	end
	
	return result
end

--[[
	returns a split u64 to two numbers, higher and lower:
]]
function module.from_u64(u64: number): (number, number)
	local high, low = 
		u64 // (module.u32_max + 1),
		bor(u64, 0)
	
	return high, low
end

module.last_bit_complement = bnot(0x01)
module.u32_max = 0xFFFF_FFFF
module.default_library = bit32

return module
