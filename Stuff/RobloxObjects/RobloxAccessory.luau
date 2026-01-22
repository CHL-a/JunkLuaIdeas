--[[
	Util module for the roblox accessory
]]

local Class = require('./Class')
local InstanceUtils = require('./@CHL>InstanceUtils')

export type roblox_accessory = Accessory & {
	Handle: BasePart;
}

local module = {}

function module.transform(attachment: Attachment): roblox_accessory
	local base_part = attachment.Parent
	
	local result = Instance.new('Accessory')
	base_part.Name = 'Handle'
	base_part.Parent = result
	
	return result
end

function module.weld_model(model: Model, weld_to: BasePart?)
	weld_to = weld_to or model.PrimaryPart
	
	assert(weld_to, 'No weld_to')
	
	for _, v in model:GetDescendants() do 
		if v:IsA('BasePart') then
			InstanceUtils.weld.apply(v, weld_to)
		end
	end
end

function module.from_model(attachment: Attachment, model: Model)
	local last_parent = model.Parent
	local result = module.transform(attachment)
	
	model.Parent = result
	result.Parent = last_parent
	
	return result
end

-- assumes that referral is to be attached to the to_attachment's parent, on that exact CFrame
function module.from_referral(to_attachment: Attachment, model: Model, referral: BasePart?)
	referral = referral or model.PrimaryPart
	
	assert(referral)
	
	local attachment = Instance.new('Attachment', referral)
	attachment.CFrame = to_attachment.CFrame
	attachment.Name = to_attachment.Name
	
	return module.from_model(attachment, model)
end

Class.make_proper_class(module, '@CHL>RobloxAccessory')

return module
