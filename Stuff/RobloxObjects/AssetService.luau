local Promise = require('./@CHL>PromiseTypes')

type promise<T> = Promise.modified_object<T>

local module = {}

Promise.implant()

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

module.service = game:GetService('AssetService')
module.models = {}

-- returns a new model instantiated from assetid
module.load_asset_raw=Promise.promisify(function(asset_id)return module.service:LoadAssetAsync(asset_id)end)::(asset_id: number) -> promise<Model>

-- returns a new model instantiated from assetid or a cached model if it hit
function module.load_asset(asset_id: number): promise<Model>
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

