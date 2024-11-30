local Set = require(script.Parent["@CHL/Set"])
export type tags = Set.simple<string>

local module = {}

function from_buffer(b: buffer): tags
	local n = buffer.len(b)
	local i = 0
	local j = 0
	local result = {}
	
	while i < n do
		local c = buffer.readu8(b, i)
		
		if c == 0x00 then
			local index = buffer.readstring(b, j, i - j)
			result[index] = true
			j = i + 1
		end
		
		i += 1
	end
	
	local last = buffer.readstring(b, j, n - j)
	result[last] = true
	
	return result
end

function from_string(s: string)
	return from_buffer(buffer.fromstring(s))
end

module.from = {}

module.from.buffer = from_buffer
module.from.string = from_string

return module
