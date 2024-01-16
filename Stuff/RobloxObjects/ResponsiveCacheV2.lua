--[[
	Returns any cached values from input "func" with given arguments
	v3
--]]

-- SPEC
export type object<returns..., params...> = {
	cache: {[string]: {any}};
	func: (params...) -> returns...;
	get: (self: object<returns..., params...>, params...) -> returns...;
	decache: (self: object<returns..., params...>,params...) -> returns...;
}

-- CLASS
local ResponsiveCache = {}

local Objects = script.Parent
local disguise = require(Objects.LuaUTypes).disguise

local availibleIndex = 0

ResponsiveCache.__index = ResponsiveCache
ResponsiveCache.nilRepresentitive = {} -- find something to replace this later
-- ^ lua doesn't allow nil indexes but allows anything else
ResponsiveCache.indexes = {}

function ResponsiveCache.new<returns..., params...>(func: (params...) -> returns...):
	object<returns...,params...>
	-- pre
	assert(type(func) == 'function')

	-- main
	local result: object<returns..., params...> = 
		disguise(setmetatable({}, ResponsiveCache))

	result.cache = {}
	result.func = func

	return result
end

function getIndex(v)
	-- pre
	v = v == nil and ResponsiveCache.nilRepresentitive or v

	if not ResponsiveCache.indexes[v] then
		availibleIndex += 1

		ResponsiveCache.indexes[v] = '_' .. availibleIndex
	end

	-- main
	return ResponsiveCache.indexes[v]
end

function getMegaIndex(...)
	local args = {...}
	local result = ''

	-- construct megaindex
	for i = 1, #args do
		result ..= getIndex(args[i])
	end

	return result
end

ResponsiveCache.getIndex = getIndex
ResponsiveCache.getMegaIndex = getMegaIndex

--[[
	Calls "func" with arguments and returns any cached values if the arguments are 
	inputted twice
]]
ResponsiveCache.get = function<r, p...>(self: object<r,p...>, ...: p...)
	-- main
	local result
	local megaIndex = ResponsiveCache:getMegaIndex(...)

	if not self.cache[megaIndex] then
		self.cache[megaIndex] = {self.func(...)}
	end

	result = self.cache[megaIndex]

	return unpack(result)
end

ResponsiveCache.exists = function<r,p...> (self:object<r,p...>, ...:p...)
	local mI = getMegaIndex(...)

	local isExist = false

	if self.cache[mI] then isExist = true end

	return isExist, unpack(self.cache[mI] or {})
end

--[[
	Decaches any entry to object.cachedResults based on the arguments, 
	returns removed value
]]
ResponsiveCache.decache = function<r..., p...>(self: object<r..., p...>, ...: p...)
	-- main
	local result = {self:get(...)}

	self.cache[getMegaIndex(...)] = nil

	return unpack(result)
end

return ResponsiveCache
