local module = {}

local Dash = require('./@CHL>DashSingular')

compose = Dash.compose

module.holder = nil
module.default_arg = workspace:FindFirstChild('Baseplate')

function module.get_holder(default: BasePart): BasePart
	if module.holder then return module.holder end
	
	default = default or module.default_arg
	
	if not default then
		default = Instance.new('Part')
		
		default.Anchored = true
		default.CanCollide = false
		default.CanTouch = false
		default.CanQuery = false
		default.Transparency = 1
		default.Name = 'GlobalAttachmentHolder'
		default.Parent = workspace
	end
	
	assert(default.Anchored)
	
	module.holder = default
	
	return default
end

function module.place(attachment: Attachment)
	local part = module.get_holder()
	local cframe = attachment.WorldCFrame
	
	attachment.Parent = part
	attachment.WorldCFrame = cframe
end

function module.place_cframe(world_cframe: CFrame): Attachment
	local result = Instance.new('Attachment')
	local part = module.get_holder()
	
	module.place(result)
	
	return result
end

module.place_position = compose(CFrame.new, module.place_cframe) :: (Vector3)->Attachment

return module
