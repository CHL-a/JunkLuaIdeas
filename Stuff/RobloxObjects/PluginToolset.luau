local module = {}

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

local PromiseTypes = require('./@CHL>PromiseTypes')
local Promise = PromiseTypes.modified.get()

type promise<T...> = PromiseTypes.modified_object<T...>

local LuaUTypes = require('./LuaUTypes')

empty = LuaUTypes.empty
disguise = LuaUTypes.disguise

module.promises = {}
module.plugin = disguise()

function module.get_plugin(): promise<Plugin>
	if module.plugin then
		return Promise.resolve(module.plugin)
	end
	
	local result = Promise.new(empty)
	
	table.insert(module.promises, result)
	
	return result
end

function module.set_plugin(plugin: Plugin)
	assert(plugin and plugin:IsA('Plugin'))
	
	module.plugin = plugin
	
	for _, promise in module.promises do
		promise:resolve(plugin)
	end
	
	module.promises = nil
end

function module.is_plugin_space(): promise<boolean>
	return Promise.new(function(
		resolve: (...any) -> (...any), 
		reject: (...any) -> (...any), 
		on_cancel: (abortHandler: ((...any) -> (...any))?) -> boolean)
		local ok, _ = module.get_plugin():await()
		
		if ok then
			resolve(true)
		else
			resolve(false)
		end
	end)
end

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

return module
