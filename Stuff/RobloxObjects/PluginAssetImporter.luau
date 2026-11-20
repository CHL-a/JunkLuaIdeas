-- plugin api from: https://github.com/CHL-a/JunkLuaIdeas/blob/main/Stuff/RobloxPlugins/QuickAssetImporter2.rbxmx
local module = {}
local InstanceUtils = require('@game/ReplicatedStorage/Objects/@CHL>InstanceUtils')
local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')
local AssetService = require('@game/ReplicatedStorage/Objects/@CHL>AssetService')

function get_bindable(): BindableFunction
	return InstanceUtils.find_first_descendant(game:GetService('ServerScriptService'), 'Bindables', 'PluginAssetImporter')
end

function module.import(asset: string): Promise.modified_object<AssetService.result_struct>
	local bindable = get_bindable()
	
	assert(bindable, 'attempting to use plugin asset importer api without system set up')
	
	return Promise.try(function(asset)
		return bindable:Invoke(asset)
	end, asset)
end

return module
