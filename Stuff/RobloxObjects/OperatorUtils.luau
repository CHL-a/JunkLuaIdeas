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

function toBool(v)return not not v end

module.superOr = superOr
module.xor = xor
module.toBool = toBool


return module
