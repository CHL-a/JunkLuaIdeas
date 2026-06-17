local AssetService = require('./@CHL>AssetService')
local Promise = require('./@CHL>Promise')

type promise<T> = Promise.modified_object<T>

local load_asset = AssetService.load_asset
local module = {}

disguise = require('./LuaUTypes').disguise

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

-- middle functions for promises

module.middle = {}

function module.middle.get_module_script<T>(model: Model): T
	return model:FindFirstChildWhichIsA('ModuleScript')
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


return module
