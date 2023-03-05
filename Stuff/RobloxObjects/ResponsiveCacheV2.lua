--[[
	Returns any cached values from input "func" with given arguments
--]]

-- SPEC
export type object<retVal, params...> = {
	cache: {[string]: {retVal}};
	func: (params...) -> retVal;
	get: (self: object<retVal, params...>, params...) -> retVal;
	decache: (params...) -> retVal;
}

-- CLASS
local ResponsiveCache = {}
local availibleIndex = 0
ResponsiveCache.__index = ResponsiveCache
ResponsiveCache.nilRepresentitive = {} -- find something to replace this later
-- ^ lua doesn't allow nil indexes but allows anything else
ResponsiveCache.indexes = {}

function ResponsiveCache.new<rVal, params...>(func: (params...) -> rVal)
	-- pre
	assert(type(func) == 'function')

	-- main
	local result = setmetatable({}, ResponsiveCache)
	local result: object<rVal, params...> = result
	
	result.cache = {}
	result.func = func
	
	return result
end

function ResponsiveCache.getIndex(v)
	-- pre
	v = v == nil and ResponsiveCache.nilRepresentitive or v

	if not ResponsiveCache.indexes[v] then
		availibleIndex += 1

		ResponsiveCache.indexes[v] = '_' .. availibleIndex
	end

	-- main
	return ResponsiveCache.indexes[v]
end

function ResponsiveCache.getMegaIndex(...)
	local args = {...}
	local result = ''

	-- construct megaindex
	for i = 1, table.getn(args) do
		result ..= ResponsiveCache.getIndex(args[i])
	end

	return result
end

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

--[[
	Decaches any entry to object.cachedResults based on the arguments, 
	returns removed value
]]
ResponsiveCache.decache = function<r, p...>(self: object<r, p...>, ...: p...)
	-- main
	local result = {self:get(...)}

	self.cache[ResponsiveCache:getMegaIndex(...)] = nil

	return unpack(result)
end

return ResponsiveCache
