--[[
	Returns any cached values from input "func" with given arguments
--]]

local ResponsiveCache = {}
local availibleIndex = 0
ResponsiveCache.nilRepresentitive = {} -- find something to replace this later
-- ^ lua doesn't allow nil indexes but allows anything else
ResponsiveCache.indexes = {}

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

export type object<retVal, params...> = {
	cache: {[string]: {retVal}};
	get: (params...) -> retVal;
	decache: (params...) -> retVal;
}

function ResponsiveCache.new<rVal, params...>(func: (params...) -> rVal)
	-- pre
	assert(type(func) == 'function')

	-- main
	local object: object<rVal, params...>
		
	object = {
		cache = {};
		--[[
			Calls "func" with arguments and returns any cached values if the arguments are 
			inputted twice
		]]
		get = function(...:params...): rVal
			-- main
			local result
			local megaIndex = ResponsiveCache:getMegaIndex(...)

			if not object.cache[megaIndex] then
				object.cache[megaIndex] = { func(...) }
			end

			result = object.cache[megaIndex]

			return unpack(result)
		end,

		--[[
			Decaches any entry to object.cachedResults based on the arguments, 
			returns removed value
		]]
		decache = function(...:params...): rVal
			-- main
			local result = {object.get(...)}

			object.cache[ResponsiveCache:getMegaIndex(...)] = nil

			return unpack(result)
		end
	}


	return object
end

return ResponsiveCache