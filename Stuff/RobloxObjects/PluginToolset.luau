local Promise = require('./@CHL>Promise')
local module = {}

Promise.implant()

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

local LuaUTypes = require('./LuaUTypes')

type promise<T...> = Promise.modified_object<T...>

empty = LuaUTypes.empty
disguise = LuaUTypes.disguise
run_service = game:GetService('RunService')

module.promised_plugin = Promise.new(empty) :: promise<Plugin | nil>
module.plugin = disguise()

-- explicit set function, while this would've been a deprecated function, this function assists with a method of a deterministic method of finding
-- plugin instead of a required explicit set
function module.set_plugin(plugin: Plugin)
	assert(plugin and plugin:IsA('Plugin'))
	
	module.plugin = plugin
	module.promised_plugin:resolve(plugin)
end

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

plugin_check = script:FindFirstAncestorWhichIsA('Plugin')

module.set_plugin(plugin_check or nil)

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

return module
