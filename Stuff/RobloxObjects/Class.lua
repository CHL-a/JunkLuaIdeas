--[[
	more modifications of such:
	 * bug fixes
]]

type __subclass<super> = super & {
	__supers: {super};
	__super: super;
}

export type subclass<A> = __subclass<A>

local Class = {}

local disguise = function<A>(x): A return x end

function getLatestFunction<A>(self: __subclass<A>, i: string)
	if i == '__supers' and not rawget(self,'__supers') then
		return
	end

	for j = #self.__supers, 1, -1 do
		local onIndex = disguise(self.__supers[j]) 

		if type(onIndex) == 'function'then return onIndex(self, i)end
		assert(type(onIndex) == 'table')

		local method = onIndex[i] 
		if not method then continue;end

		return method
	end

	-- print(self.__supers)
	-- error(`Missing method: {i}`)
end

local super_metatable = {__index = getLatestFunction}

function inherit<A>(t: A, methods, is_debugging): __subclass<A>
	local result: __subclass<A> = disguise(t)
	local supers = result.__supers or {}
	result.__supers = supers

	-- metatable evaluation
	local old_metatable = getmetatable(disguise(result))

	if old_metatable and
		old_metatable.__index and
		old_metatable.__index ~= getLatestFunction then
		table.insert(supers, old_metatable.__index)
	end

	if methods then
		table.insert(supers, methods)
	end

	setmetatable(disguise(result), super_metatable) -- do something here later?

	result.__super = supers[#supers - 1]
	
	--[[
	if not result.__super then
		print(result.__supers, methods, old_metatable)
		error('missing inheritance function')
	end
	--]]
	
	return result
end

Class.inherit = inherit

return Class
