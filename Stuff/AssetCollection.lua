-- SPEC
export type object = {
	assetIds: {string};
	
	getAssetId: (self: object) -> string;
}

-- CLASS
local MeshAsset = {}
local isStudio = game['Run Service']:IsStudio()
local Content = require(script.Content)

MeshAsset.__index = MeshAsset

MeshAsset.new = function(...: string | number)
	local result = setmetatable({}, MeshAsset)
	local result : object = result
	
	local ids = {...}
	for i, v in next, ids do
		if not Content.getComponents(v) then
			ids[i] = 'rbxassetid://' .. v
		end
	end
	
	result.assetIds = ids
	
	return result
end

MeshAsset.getAssetId = function(self: object)
	local result
	
	for _, v in next, self.assetIds do
		local protocol, _ = Content.getComponents(v)
		local protocol : Content.protocol = protocol
		
		if not protocol then warn(`non content: {v}`) continue end
		
		if protocol == 'rbxasset' and isStudio then
			result = v;
			break
		elseif protocol == 'rbxassetid' then
			result = v;
		else
			error(`got bad asset: {v}`)
		end
	end
	
	return result
end

return MeshAsset
