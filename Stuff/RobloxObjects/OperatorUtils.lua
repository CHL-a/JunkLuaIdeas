local module = {}

function xor(a, b)return (a or b) and not (a and b)end

function superOr(a, ...)
	for i = 1, select('#', ...) do
		local b = select(i, ...)
		if a == b then
			return true
		end
	end
	
	return false
end

module.superOr = superOr
module.xor = xor

return module
