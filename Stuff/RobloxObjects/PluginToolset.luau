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
is_server = run_service:IsServer()
is_client = run_service:IsClient()

module.promised_plugin = Promise.new(empty) :: promise<Plugin?>
module.plugin = disguise()

-- explicit set function, while this would've been a deprecated function, this function assists with a method of a deterministic method of finding
-- plugin instead of a required explicit set
function module.set_plugin(plugin: Plugin)
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

export type space_type = 'studio' | 'server' | 'client' | 'unknown'

function module.get_space_type(): space_type
	if not module.plugin then
		return 'unknown'
	end
	
	if is_server and is_client then
		return 'studio'
	elseif is_server then
		return 'server'
	elseif is_client then
		return 'client'
	else
		return 'unknown'
	end
end

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

return module
