local Promise = require('./@CHL>Promise')

type promise<T> = Promise.modified_object<T>

local module = {}

Promise.implant()

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

local PluginToolset = require('./@CHL>PluginToolset')

module.service = game:GetService('AssetService')
module.models = {}

-- returns a new model instantiated from assetid
module.load_asset_raw = Promise.promisify(function(asset_id)
	local plugin = PluginToolset.get_plugin():expect()
	
	if plugin then
		return game:GetObjects(`rbxassetid://{asset_id}`)
	end
	
	return module.service:LoadAssetAsync(asset_id):GetChildren()
end)::(asset_id: number) -> promise<{Instance}>

-- returns a new model instantiated from assetid or a cached model if it hit
function module.load_asset(asset_id: number): promise<{Instance}>
	local promised_models = module.models
	
	if promised_models[asset_id] then
		return promised_models[asset_id]
	end
	
	local result = module.load_asset_raw(asset_id)
	
	promised_models[asset_id] = result
	
	return result
end

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

return module

