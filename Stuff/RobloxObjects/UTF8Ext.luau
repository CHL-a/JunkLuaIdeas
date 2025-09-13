local module = {}

band = bit32.band
lshift = bit32.lshift
bor = bit32.bor

--[[
Parameters:
get: A read only function which retrieves a number
proceed: advances external implementation to make get() return a new number, which may be different from the last

Returns: code_point?, nil if error
]]
function module.parse(get: ()->number, proceed: ()->()): (number?)
	local code_point = 0
	local size = 1
	local first = get()
	
	size =  band(first, 0b1000_0000) == 0b0000_0000 and 1 or
			band(first, 0b1110_0000) == 0b1100_0000 and 2 or 
			band(first, 0b1111_0000) == 0b1110_0000 and 3 or 
			band(first, 0b1111_1000) == 0b1111_0000 and 4 or nil
	
	if not size then
		proceed()
		return
	end
	
	local code_point = 
		size == 1 and band(first, 0x0111_1111) or 
		size == 2 and band(first, 0b0001_1111) or 
		size == 3 and band(first, 0b0000_1111) or 
		size == 4 and band(first, 0b0000_0111)
	
	size -= 1
	
	proceed()
	
	for i = 1, size do
		local current = get()
		
		if band(current, 0b1100_0000) ~= 0b1000_0000 then
			return
		end
		
		code_point = lshift(code_point, 6)
		code_point = bor(code_point, band(current, 0b0011_1111))
		proceed()
	end
	
	return code_point
end

module.default_library = utf8

return module
