local Class = require('./Class')
local Object = require('./Object')
local InstanceUtils = require('./@CHL>InstanceUtils')
local player = game:GetService('Players').LocalPlayer
local service = game:GetService('ProximityPromptService')

local module = {}
local proximity_prompt = {}

--######################################################################################################################################################################################################
--######################################################################################################################################################################################################
--######################################################################################################################################################################################################

export type proximity_prompt = {
	frame: ProximityPrompt,
	
	hold: (self: proximity_prompt) -> (),
	release: (self: proximity_prompt) -> (),
	emit_fade: (self: proximity_prompt) -> (),
	detach: (self: proximity_prompt) -> (),
	destroy: (self: proximity_prompt) -> (),
	get_proximity_prompt: (self: proximity_prompt) -> ProximityPrompt,
	get_world_position: (self: proximity_prompt) -> Vector3,
	update: (self: proximity_prompt, dt: number) -> ();
	
}

local LuaUTypes = require('./LuaUTypes')

cast = LuaUTypes.explicit_cast

function proximity_prompt.new(frame: Frame): proximity_prompt
	local self: proximity_prompt = Object.simple.new(proximity_prompt)
	
	self.frame = frame
	
	return self
end

function proximity_prompt.from_proximity_prompt(prompt: ProximityPrompt): proximity_prompt
	if not (prompt.Style == Enum.ProximityPromptStyle.Custom and prompt:GetAttribute('is_hm_proximity_prompt')) then return end
	
	local referral = prompt:FindFirstChild('referral')
	
	if referral then
		return proximity_prompt.new(referral.Value)
	end
	
	local clone = assert(proximity_prompt.template_frame, 'missing template_frame'):Clone()
	local gui = module.parent
	local result = proximity_prompt.new(clone)
	local uri = prompt:GetAttribute('uri')
	
	referral = Instance.new('ObjectValue')
	
	referral.Name = 'referral'
	referral.Value = clone
	referral.Parent = prompt
	
	clone.prompt.Value = prompt
	clone.bottom_progress.Visible = false
	clone.top_progress.Visible = false
	clone.left_progress.Visible = false
	clone.right_progress.Visible = false
	clone.Parent = gui
	
	if uri then
		cast<<(ImageLabel)>>(clone.bg.ImageLabel).ImageContent = Content.fromUri(uri)
	end
	
	return result
end

function proximity_prompt.detach(self: proximity_prompt)
	self.frame = nil
end

function proximity_prompt.destroy(self: proximity_prompt)
	local back_referral = self:get_proximity_prompt():FindFirstChild('referral')
	
	if back_referral then
		back_referral.Value = nil
		back_referral:Destroy()
	end
	
	self.frame.prompt.Value = nil
	self.frame:Destroy()
	
	self:detach()
end

function proximity_prompt.emit_fade(self: proximity_prompt)
	local frame = self.frame
	
	frame.short:Play()
	frame:SetAttribute('elapsed', 0)
	
	local clone = frame:Clone()
	clone:SetAttribute('size', '/bg')
	clone:SetAttribute('fading', '/bg')
	clone:SetAttribute('fading_2', '/bg/ImageLabel')
	clone:SetAttribute('class', 'fading_frame')
	clone.Parent = frame.Parent
end

function proximity_prompt.hold(self: proximity_prompt)
	local frame = self.frame
	frame.long:Play()
	frame:SetAttribute('held', true)
end

function proximity_prompt.release(self: proximity_prompt)
	local frame = self.frame

	frame.long:Stop()
	frame:SetAttribute('held', false)
	frame:SetAttribute('elapsed', 0)
	frame.bottom_progress.Visible = false
	frame.left_progress.Visible = false
	frame.right_progress.Visible = false
	frame.top_progress.Visible = false
end

function proximity_prompt.get_proximity_prompt(self: proximity_prompt): ProximityPrompt
	return self.frame.prompt.Value
end

function proximity_prompt.get_world_position(self: proximity_prompt)
	return self:get_proximity_prompt().Parent.Position
end

function proximity_prompt.update(self: proximity_prompt, dt: number)
	local position_3d = self:get_world_position()
	local position_2d, is_visible = module.camera:WorldToScreenPoint(position_3d)
	local frame = self.frame
		
	frame.Visible = is_visible
	frame.Position = UDim2.fromOffset(position_2d.X, position_2d.Y)
	
	local is_held = frame:GetAttribute('held')
	
	if is_held then
		local elapsed = frame:GetAttribute('elapsed') + dt
		local prompt = self:get_proximity_prompt()
		local alpha = math.min(elapsed / prompt.HoldDuration, 1)
		
		frame:SetAttribute('elapsed', elapsed)
			
		frame.bottom_progress.Visible = is_held
		frame.left_progress.Visible = is_held
		frame.right_progress.Visible = is_held
		frame.top_progress.Visible = alpha >= 1 and prompt.HoldDuration > 0
		
		frame.left_progress.Size = UDim2.fromOffset(1, 36 * alpha)
		frame.right_progress.Size = UDim2.fromOffset(1, 36 * alpha)
	end
end

Class.make_proper_class(proximity_prompt, 'HellmetUI>ProximityPrompt')

proximity_prompt.template_frame = InstanceUtils.find_first_descendant(game:GetService('ReplicatedStorage'), 'custom_prox')
module.parent = player.PlayerGui:WaitForChild('hm_ui_prox', 5) -- subject to be a promise
module.camera = workspace.CurrentCamera
module.proximity_prompt = proximity_prompt

--######################################################################################################################################################################################################
--######################################################################################################################################################################################################
--######################################################################################################################################################################################################

export type fading_frame = {
	root: Frame;
	growing: {GuiObject};
	fading: {GuiObject};
	is_destroyed: boolean?;
	
	detach: (self: fading_frame) -> (),
	destroy: (self: fading_frame) -> (),
	update: (self: fading_frame) -> (),
}

local Hierarchy = require('./@CHL>Hierarchy')

fading_frame = {}

function fading_frame.new(frame: Frame): fading_frame
	local self: fading_frame = Object.simple.new(fading_frame)
	local find_instance = Hierarchy.instance_path_parser.invoke_query
	
	self.root = frame
	self.growing = {find_instance{query = frame:GetAttribute('size'),root_instance = frame}}
	self.fading = {find_instance{query = frame:GetAttribute('fading'),root_instance = frame}}
	
	local i = 2
	local value = frame:GetAttribute(`size_{i}`)
	while value do
		table.insert(self.growing, find_instance{query = value,root_instance = frame})
		i += 1
		value = frame:GetAttribute(`size_{i}`)
	end
	
	i = 2
	value = frame:GetAttribute(`fading_{i}`)
	while value do
		table.insert(self.fading, find_instance{query = value,root_instance = frame})
		i += 1
		value = frame:GetAttribute(`fading_{i}`)
	end
	
	frame.ZIndex = -1
	
	return self
end

function fading_frame.detach(self: fading_frame)
	self.root = nil
	self.frame = nil
end

function fading_frame.destroy(self: fading_frame)
	self.root:Destroy()
	self:detach()
	self.is_destroyed = true
end

function fading_frame.update(self: fading_frame)
	local frame = self.frame
	
	for _, v in self.growing do
		v.Size = UDim2.fromOffset(
			v.Size.X.Offset + 1,
			v.Size.Y.Offset + 1
		)
	end
	
	local is_transparent
	
	for _, v in self.fading do
		if v:IsA('ImageLabel') then
			v.ImageTransparency += .05
			
			is_transparent = v.ImageTransparency >= 1
		else
			v.BackgroundTransparency += .05
			
			is_transparent = v.BackgroundTransparency >= 1
		end
	end
	
	if is_transparent then
		self:destroy()
	end
end

Class.make_proper_class(fading_frame, 'HellmetUI>FadingFrame')

module.fading_frame = fading_frame

--######################################################################################################################################################################################################
--######################################################################################################################################################################################################
--######################################################################################################################################################################################################

function module.init()
	module.connections.prompt_shown = service.PromptShown:Connect(function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
		proximity_prompt.from_proximity_prompt(prompt)
			:detach()
	end)

	module.connections.prompt_hidden = service.PromptHidden:Connect(function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
		local object: proximity_prompt = proximity_prompt.from_proximity_prompt(prompt)
		
		if not object then return end
		
		object:destroy()
	end)
	
	module.connections.prompt_triggered = service.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player) 		
		local object = proximity_prompt.from_proximity_prompt(prompt)
		
		if not object then
			return
		end
		
		object:emit_fade()
		object:detach()
	end)
	
	module.connections.prompt_held = service.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		local object = proximity_prompt.from_proximity_prompt(prompt)
		
		if not object then
			return
		end
		
		object:hold()
		object:detach()
	end)
	
	module.connections.prompt_released = service.PromptButtonHoldEnded:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		local object = proximity_prompt.from_proximity_prompt(prompt)
		
		if not object then
			return
		end
		
		object:release()
		object:detach()
	end)
	
end

function module.update(dt: number)
	for _, frame in module.parent:GetChildren() do
		local class = frame:GetAttribute('class')
		local element;
		if class == 'proximity_prompt' then
			element = proximity_prompt.new(frame)
		elseif class == 'fading_frame' then
			element = fading_frame.new(frame)
		else
			print(class)
		end
		
		element:update(dt)
		
		if not element.is_destroyed then
			element:detach()
		end
	end
end

function module.undo_init()
	for _, connection in module.connections do
		connection:Disconnect()
	end
	
	table.clear(module.connections)
end

module.connections = {}

--######################################################################################################################################################################################################
--######################################################################################################################################################################################################
--######################################################################################################################################################################################################

return module
