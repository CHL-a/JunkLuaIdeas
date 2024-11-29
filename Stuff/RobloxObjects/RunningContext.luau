export type result = 'game' | 'plugin' | 'command_line' | 'unknown'

disguise = require(script.Parent.LuaUTypes).disguise

local context = disguise() :: result

return function()
	if context then return context end
	
	local env = getfenv(disguise(0))
	
	local plugin_check: Plugin? = env.plugin
	local script_check: BaseScript = env.script
	
	context = (
		if plugin_check ~= nil 
			then
				if typeof(plugin_check) == 'Instance' and plugin_check:IsA('Plugin') 
					then 'plugin'
					else 'unknown'
		elseif script_check ~= nil 
			then
				if typeof(script_check) == 'Instance' and script_check:IsA('BaseScript') 
					then 'game'
					else 'unknown'
		else 'command_line'
	) :: result
		
	return context
end
