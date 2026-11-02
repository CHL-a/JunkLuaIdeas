--[[
	From: 
	 * http://www.gamedev.net/reference/articles/article1941.asp
	 * https://github.com/davidm/lua-digest-crc32lua/blob/master/lmod/digest/crc32lua.lua
	 * https://github.com/luvit/zlib/blob/master/crc32.c
	 
	may not be compliant
]]

local module = {}

band = bit32.band
rshift = bit32.rshift
bxor = bit32.bxor
bnot = bit32.bnot

function module.look_up_value_calc(byte: number, poly: number?): number
	poly = poly or module.magics.default_poly
	local result = byte
	
	for i = 1, 8 do
		local bit = band(result, 1)
		result = rshift(result, 1)
		
		if bit == 1 then
			result = bxor(result, poly)
		end
	end
	
	return result
end

function module.look_up_value_of(byte: number, poly: number?): number
	module.look_up_table[byte] = module.look_up_table[byte] or module.look_up_value_calc(byte, poly)
	
	return module.look_up_table[byte]
end

function module.iterate(byte: number, previous_crc: number?): number
	previous_crc = previous_crc or 0
	
	local uint = rshift(previous_crc, 8)
	local byte = module.look_up_value_of(bxor(band(previous_crc, 0xFF), byte))
	
	return bnot(bxor(uint, byte))
end

module.look_up_table = {}
module.magics = {
	default_poly = 0xEDB88320; -- koopman
}

return module
