local AssetService = require('./@CHL>AssetService')
local Promise = require('./@CHL>Promise')

type promise<T> = Promise.modified_object<T>

local load_asset = AssetService.load_asset
local module = {}

disguise = require('./LuaUTypes').disguise
is_client = game:GetService('RunService'):IsClient()

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

-- middle functions for promises

module.middle = {}

function module.middle.get_module_script(model: Model): ModuleScript
	return model:FindFirstChildWhichIsA('ModuleScript')
end

function module.middle.move_to_repo(instance: Instance)
	instance.Parent = script.Parent
end

function module.middle.repo_await(...: string)
	local n = select('#', ...)
	local current = script.Parent
	local known_name
	for i = 1, n do
		known_name = select(i, ...)
		
		current = current:WaitForChild(known_name, 10)
		
		if not current then
			break
		end
	end
	
	assert(current, `LuaULibs.middle.repo_await: repo fetch failure, timeout reached: known_name={known_name}`)
	
	return current
end

function module.middle.imprint<T>(from: T, to: any, specific_indices: any?): T
	local iterable = specific_indices or from
	
	for i, v in iterable do
		local j = typeof(v) == 'string' and v or i
		
		to[i] = from[j]
	end
	
	return from
end

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################



return module
