type __subclass<super> = super & {
	__supers: {super};
	__super: super;
}

export type subclass<A> = __subclass<A>

local Class = {}

local disguise = function<A>(x): A return x end

function getLatestFunction<A>(self: __subclass<A>, i: string)
	assert(i ~= '__supers', 'self missing index __supers')

	for j = #self.__supers, 1, -1 do
		local onIndex = disguise(self.__supers[j]) 

		if type(onIndex) == 'function'then return onIndex(self, i)end
		assert(type(onIndex) == 'table')

		local method = onIndex[i] 
		if not method then continue;end

		return method
	end

	print(self.__supers)
	error(`Missing method: {i}`)
end

function inherit<A>(t: A, methods): __subclass<A>
	local result: __subclass<A> = disguise(t)
	result.__supers = result.__supers or {}

	-- metatable evaluation
	local metatable = getmetatable(disguise(result))

	if methods and metatable then
		if metatable.__index ~= getLatestFunction then
			table.insert(result.__supers, metatable.__index)
			metatable.__index = getLatestFunction
		end

		table.insert(result.__supers, methods)

		setmetatable(disguise(result), metatable)
	end
	
	result.__super = result.__supers[#result.__supers - 1]

	return result
end

Class.inherit = inherit

return Class
