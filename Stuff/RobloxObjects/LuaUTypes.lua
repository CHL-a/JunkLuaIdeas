local module = {}

function same(x)return x end

module.assertify = function<A>(val: A?): A
	return same(val)
end

module.disguise = function<A>(val: any): A
	return same(val)
end

return module
