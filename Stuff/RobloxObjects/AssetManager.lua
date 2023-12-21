-- interfaces
type __asset_manager = {
	getAnimationId: (self:__asset_manager, id: string | KeyframeSequence) -> string;
	getAnimation: (self:__asset_manager, id: string | KeyframeSequence) -> Animation;
	checkFolder: (self:__asset_manager, name: string) -> Folder;
}
export type asset_manager = __asset_manager

-- deps
local disguise = require(script.Parent.LuaUTypes).disguise

-- modules
local module = {}
module.__index = module

module.new = function(): __asset_manager
	local self: __asset_manager = disguise(setmetatable({}, module))
	
	self:checkFolder('Animations')
	
	return self
end

module.checkFolder = function(self:__asset_manager, name: string)
	local result = script:FindFirstChild(name)
	
	if not result then
		local folder = Instance.new('Folder')
		
		folder.Name = name
		folder.Parent = script
		result = folder
	end
	
	return result
end

module.getAnimationId = function(self:__asset_manager, id: string | KeyframeSequence)
	local k: KeyframeSequence
	
	if type(id) == 'string' then
		k = script.Animations:FindFirstChild(id)
	elseif typeof(id) == 'Instance' and id:IsA('KeyframeSequence') then
		k = id
	end
	
	assert(k, `missing id:{id}`)
	
	return game:GetService('KeyframeSequenceProvider')
		:RegisterKeyframeSequence(k)
end

module.getAnimation = function(self:__asset_manager, id: string | KeyframeSequence)
	local animation_id = self:getAnimationId(id)
	
	local animation = Instance.new('Animation')
	animation.AnimationId = animation_id
	
	return animation
end



return module.new() :: asset_manager
