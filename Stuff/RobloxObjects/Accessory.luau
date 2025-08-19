local Object = require('./Object')
local EventPackage = require('./EventPackage')
local InstanceUtils = require('./@CHL>InstanceUtils')

export type object = {
	hasCollision: boolean;
	hasMass: boolean;
	model : Model;
	isDestroyed: boolean;
	partWeld: Weld;
	
	getMiddle : (self: object, Model?) -> BasePart;
	clone: (self:object)->object;
	attachTo : (self: object, part: BasePart, parent: Instance) -> Model;
	destroy: (self: object) -> ();
	
	__attached: EventPackage.package<BasePart?, Instance?>;
	attached: EventPackage.event<BasePart?, Instance?>;
	__destroyed: EventPackage.package<BasePart?, Instance?>;
	destroyed: EventPackage.event<BasePart?, Instance?>;
} & Object.object_inheritance

Accessory = {}

function Accessory.new(model: Model, hasCollision, hasMass)
	-- pre
	hasCollision = not not hasCollision
	hasMass = not not hasMass
	assert(typeof(model) == 'Instance' and (model:IsA('Model') or model:IsA('Folder')), 
		`model issue: {typeof(model)}|{model}`
	)
	model = model:Clone()
	
	-- main
	local self: object = Object.from.class(Accessory)
	self.model = model
	self.hasMass = hasMass
	self.hasCollision = hasCollision
	self:__constructEvent('attached', 'destroyed')
	
	--[[
	object.model.AncestryChanged:Connect(function()
		if not object.model:IsDescendantOf(game) then
			object.__destroyed.fire(nil, nil)
		end
	end)
	--]]
	
	local middle = self:getMiddle()
	
	for _, v in model:GetDescendants() do
		if typeof(v) ~= 'Instance' then  continue end
	
		if not v:IsA('BasePart') then continue end
		v.Anchored = false
		
		if not hasCollision then
			v.CanCollide = false
		end
		
		if not hasMass then
			v.Massless = true
		end
		
		InstanceUtils.weld.apply(middle, v)
	end
	
	return self
end

function Accessory.destroy(self:object)
	local a,b = self.partWeld and self.partWeld.Part0, self.model.Parent
	self.model:Destroy()
	self.isDestroyed = true
	self.__destroyed:fire(a,b)
end

function Accessory.clone(self:object)
	assert(not self.isDestroyed, 'Attempting to use destroyed object')
	
	return Accessory.new(self.model:Clone(),self.hasCollision,self.hasMass)
end

function Accessory.getMiddle(self:object, model)
	assert(not self.isDestroyed, 'Attempting to use destroyed object')
	model = model or self.model

	local result = 
		model:IsA('Model')
			and model.PrimaryPart
			or model:FindFirstChild('Middle')

	assert(result and result:IsA'BasePart')

	return result
end

function Accessory.attachTo(self:object, part, parent)
	-- pre
	assert(not self.isDestroyed, 'Attempting to use destroyed object')
	assert(typeof(part) == 'Instance' and part:IsA('BasePart'))

	-- main
	local m = self.model
	self.partWeld = InstanceUtils.weld.apply(part,self:getMiddle(), CFrame.identity)
	m.Parent = parent or part
	
	self.__attached:fire(part, m.Parent)
	
	return m
end

require('./Class').makeProperClass(Accessory, '@CHL>Accessory')

return Accessory
