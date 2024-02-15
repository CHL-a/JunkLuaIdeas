--// TYPEs
local Objects = script.Parent
local EventPackage = require(Objects.EventPackage)
local Map = require(Objects["@CHL/Map"])

type map<I, V> = Map.simple<I, V>

export type object = {
	name: string;
	frame: Frame;
	isConstructed: boolean;
	
	__assignEvent: (self: object, s: string) -> nil;
	getFrameAt: (self: object, parent: Instance) -> Frame;
	
	__appeared: EventPackage.package<
		ProximityPrompt, 
		Enum.ProximityPromptInputType,
		Frame>;
	appeared: EventPackage.event<
		ProximityPrompt,
		Enum.ProximityPromptInputType,
		Frame>;
	__hidden: EventPackage.package<ProximityPrompt, Frame>;
	hidden: EventPackage.event<ProximityPrompt, Frame>;
	__heldDown: EventPackage.package<ProximityPrompt, Frame>;
	heldDown: EventPackage.event<ProximityPrompt, Frame>;
	__heldEnded: EventPackage.package<ProximityPrompt, Frame>;
	heldEnded: EventPackage.event<ProximityPrompt, Frame>;
	__cloned: EventPackage.package<ProximityPrompt, Frame>;
	cloned: EventPackage.event<ProximityPrompt, Frame>;
	__triggered: EventPackage.package<ProximityPrompt, Frame>;
	triggered: EventPackage.event<ProximityPrompt, Frame>;
}

-- // MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

service = game:GetService('ProximityPromptService')
disguise = LuaUTypes.disguise
module.__index = module
module.default_index = '__default'
module.objects = {} :: map<string, object>

function getBillboardGui(parent: ProximityPrompt)
	local found = parent:FindFirstChild('__custom_billboard_gui')
	if found then return found end
	
	local result: BillboardGui = disguise(script:FindFirstChild('template_billboard_gui'))
	
	if not result then
		local temp = Instance.new('BillboardGui')
		temp.AlwaysOnTop = true
		temp.Name = 'template_billboard_gui'
		temp.Size = UDim2.fromScale(2.5, 2)
		temp.StudsOffset = Vector3.yAxis
		temp.ZIndexBehavior = Enum.ZIndexBehavior.Global
		temp.ClipsDescendants = false
		temp.Parent = script
		
		local uIList = Instance.new('UIListLayout')
		uIList.VerticalAlignment = Enum.VerticalAlignment.Center
		uIList.Parent = temp
		
		result = temp;
	end

	result = result:Clone()
	result.Name = '__custom_billboard_gui'
	result.Parent = parent
	result.Adornee = parent.Parent
	
	return result
end

function getObject(prompt: ProximityPrompt): (object?, Frame?)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end;
	local gotIndex = prompt:GetAttribute('__custom_proximity')
	local index = gotIndex or module.default_index
	local object: object = module.objects[index]
	
	if not object then
		if gotIndex then
			warn(`Attempting to access a non existant Custom Proximity Prompt of \z
				name: {gotIndex}`)
		end
		
		return
	end
	
	local bbG = getBillboardGui(prompt)
	
	return object, object:getFrameAt(bbG)
end

function shown(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local o, f = getObject(prompt)
	if not o then return end
	
	o.__appeared:fire(prompt, inputType, f)
end

function hidden(prompt: ProximityPrompt)
	local o, f = getObject(prompt)
	if not o then return end
	
	o.__hidden:fire(prompt, f)
end

function held(prompt: ProximityPrompt)
	local o, f = getObject(prompt)
	if not o then return end
	
	o.__heldDown:fire(prompt, f)
end

function released(prompt:ProximityPrompt)
	local o, f = getObject(prompt)
	if not o then return end
	
	o.__heldEnded:fire(prompt, f)
end

function triggered(prompt:ProximityPrompt)
	local o, f = getObject(prompt)
	if not o then return end

	o.__triggered:fire(prompt, f)
end

function module.get(name: string): object? return module.objects[name] end

function module.new(name: string, frame: Frame): object
	-- pre
	assert(name, "Attempting to pass bad name.")
	local found = module.get(name)
	if found then return found end;
	
	assert(frame, "No referal frame")
	
	-- main
	local self: object = disguise(setmetatable({}, module))
	self.name = name
	self.frame = frame
	
	self:__assignEvent('__appeared')
	self:__assignEvent('__hidden')
	self:__assignEvent('__heldDown')
	self:__assignEvent('__heldEnded')
	self:__assignEvent('__cloned')
	self:__assignEvent('__triggered')

	module.objects[name] = self
	
	self.isConstructed = true
	
	return self;
end

module.getFrameAt = function(self: object, p: Instance)
	local result = p:FindFirstChild(self.name, true)
	
	if not result then
		local c = self.frame:Clone()
		c.Name = self.name
		c.Parent = p
	
		self.__cloned:fire(
			disguise(p:FindFirstAncestorWhichIsA('ProximityPrompt')), 
			self.frame
		)
		
		result = c
	end
	
	return result
end

module.__assignEvent = function(self: object, s: string)
	assert(not self.isConstructed, "Attempting to access private method")
	
	local p = EventPackage.new()
	local _s = disguise(self)
	
	_s[s] = p
	_s[s:sub(3)] = p.event
end

service.PromptShown:Connect(shown)
service.PromptHidden:Connect(hidden)
service.PromptButtonHoldBegan:Connect(held)
service.PromptButtonHoldEnded:Connect(released)
service.PromptTriggered:Connect(triggered)

return module
