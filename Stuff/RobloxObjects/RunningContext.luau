export type context = 'game' | 'plugin' | 'unknown'

local module = {}

--############################################################################################################################################################
--############################################################################################################################################################
--############################################################################################################################################################

-- section for determining current running context

--[[
	Attempts to determine if the code is running in a plugin or in the game.
]]
function module.test_context(): context
	if module.did_test then return module.get_context()end
	
	local success = pcall(function()script.RobloxLocked = script.RobloxLocked end)
	local context: context = if success then 'plugin' else 'game'
	
	module.did_test = true
	module.context = context
	return module.get_context()
end

--[[
	returns context
]]
function module.get_context(): context return module.context end

function module.is_game(): boolean return module.test_context() == 'game' end
function module.is_plugin(): boolean return module.test_context() == 'plugin' end

module.did_test = false
module.context = 'unknown' :: context

--############################################################################################################################################################
--############################################################################################################################################################
--############################################################################################################################################################

-- section for variables

function verify_plugin_api(api: string)
	local context: context = module.get_context()
	
	assert(context == 'plugin', `Api .{api} is unavailible for {context}`)
end

function module.set_plugin_variable(plugin: Plugin)
	verify_plugin_api('set_plugin_variable()')
	
	module.plugin_variable = plugin
end

function module.get_plugin(): Plugin
	verify_plugin_api('get_plugin()')
	
	local result = module.plugin_variable
	
	assert(result, 'failed to retrieve plugin: dev did not assign it. use .set_plugin_variable(plugin)')
	
	return result
end

module.plugin_variable = nil

return module
