local Promise = require('./@CHL>Promise')

type promise<T> = Promise.modified_object<T>

local module = {}

Promise.implant()

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

export type result_struct = {
	asset: any;
	success: boolean;
	instances: {Instance};
	message: string;
}

local PluginToolset = require('./@CHL>PluginToolset')

module.service = game:GetService('AssetService')
module.structs = {}

-- returns a new model instantiated from assetid
module.load_asset_raw = Promise.promisify(function(asset)
	local plugin = PluginToolset.promised_plugin:expect()
	
	result.asset = asset
	
	if typeof(asset) == 'string' and plugin then
		return game:GetObjects(`rbxasset://{asset}`)
	end
	
	if plugin then
		return game:GetObjects(`rbxassetid://{asset}`)
	end
	
	return module.service:LoadAssetAsync(asset):GetChildren()
	
end)::(asset_id: number) -> promise<{Instance}>

-- returns a new model instantiated from assetid or a cached model if it hit
function module.load_asset(asset: any): promise<result_struct>
	local promised_structs = module.structs
	
	if promised_structs[asset] then
		return promised_structs[asset]
	end
	
	local result = module.load_asset_raw(asset)
		:append_args(asset)
		:upon(function(array, asset)
			return {
				asset = asset;
				success = true;
				instances = array;
			} :: result_struct
		end)
		:catch(function(err, ...): ...any
			return {
				asset = asset;
				success = false;
				message = tostring(err);
			} :: result_struct
		end)
	
	promised_models[asset] = result
	
	return result
end

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

return module

