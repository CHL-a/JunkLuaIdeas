local Objects = script.Parent
local Object = require(Objects.Object)
local Destructable = require(Objects["@CHL/Destructable"])
local EventPackage = require(Objects.EventPackage)
local module = {}

--#############################################################################################
--#############################################################################################
--#############################################################################################

type package<A...> = EventPackage.package<A...>
type event<A...> = EventPackage.event<A...>

export type component = {
	model: Model;
	hasCollision: boolean;
	hasMass: boolean;
	weld: Weld?;
	
	updateModel: (self:component) -> ();
	attachTo: (self: component, part: BasePart, parent: Instance) -> ();
	detatch: (self: component) -> ();
	getReference: (self: component) -> BasePart;
	clone: (self: component) -> component;
	
	__attached: package<BasePart?, Instance?>;
	attached: event<BasePart?, Instance?>;
	__destroyed: package<BasePart?, Instance?>;
	destroyed: event<BasePart?, Instance?>;
} & Object.object_inheritance
  & Destructable.object

AccessoryComponent = {}

local InstanceUtils = require(Objects["@CHL/InstanceUtils"])

function AccessoryComponent.new(model: Model): component
	local self: component = Object.from.class(AccessoryComponent)
	self.model = model
	self.hasCollision = false
	self.hasMass = false
	
	self:__constructEvent('attached', 'destroyed')
	
	local ref = self:getReference()
	
	for _, v in next, model: GetDescendants() do
		if v:IsA('BasePart') then
			InstanceUtils.weld.apply(ref, v)
			v.Anchored = false;
		end
	end
	
	return self
end

function AccessoryComponent.getReference(self:component, model)
	assert(not self.isDestroyed, 'Attempting to use destroyed object')
	model = model or self.model

	local result = 
		model:IsA('Model')
		and model.PrimaryPart
		or model:FindFirstChild('Middle')

	assert(result and result:IsA'BasePart', `Missing middle of instance: {model:GetFullName()}`)

	return result
end

function AccessoryComponent.updateModel(self: component)
	for _, v in next, self.model:GetDescendants() do
		if not v:IsA('BasePart') then continue end
		
		v.CanCollide = self.hasCollision
		v.Massless = not self.hasMass
	end
end

function AccessoryComponent.clone(self:component)
	assert(not self.isDestroyed, 'Attempting to use destroyed object')

	local result = AccessoryComponent.new(self.model:Clone())
	result.hasCollision = self.hasCollision;
	result.hasMass = self.hasMass
	return result
end

function AccessoryComponent.destroy(self: component)
	local a,b = self.weld and self.weld.Part0, self.model.Parent
	self.model:Destroy()
	self.isDestroyed = true
	self.__destroyed:fire(a,b)
end

function AccessoryComponent.detatch(self: component)
	assert(self.weld)
	self.weld:Destroy()
	self.weld = nil
end

function AccessoryComponent.attachTo(
	self: component, 
	part: BasePart, 
	parent: Instance)
	-- pre
	assert(not self.isDestroyed, 'Attempting to use destroyed object')
	assert(typeof(part) == 'Instance' and part:IsA('BasePart'))
	assert(not self.weld, 'Attempting to attach an attached object')

	-- main
	local m = self.model
	self.weld = InstanceUtils.weld.apply(part, self:getReference(), CFrame.identity)
	m.Parent = parent or part

	self.__attached:fire(part, m.Parent)

	return m
end

AccessoryComponent.Destroy = AccessoryComponent.destroy
AccessoryComponent.__index = AccessoryComponent
AccessoryComponent.className = 'AcccessoryV3/Component'

module.accessoryComponent = AccessoryComponent

--#############################################################################################
--#############################################################################################
--#############################################################################################

local Map = require(Objects["@CHL/Map"])
local Dash = require(Objects["@CHL/DashSingular"])
local ComposeOperations = require(Objects["@CHL/ComposeOperations"])
local Status = require(Objects["@CHL/Status"])

type map<I, V> = Map.simple<I, V>
type dict<A> = Map.dictionary<A>
type status = Status.object<Model>

export type componentMap = map<{string}, {component}>

export type object = {
	components: componentMap;
	name: string;
	model: Model;
	statuses: {status}?;

	attachTo: (self: object, parent: Instance) -> ();
	detatch: (self: object) -> ();
	clone: (self: object) -> object;

	__attached: package<Instance>;
	attached: event<Instance>;
	__destroyed: package<>;
	destroyed: event<>;
} & Object.object_inheritance

AccessoryV3 = {}

AccessoryV3.componentsArgs = {}
AccessoryV3.componentsArgs.from = {}
AccessoryV3.from = {}

disguise = require(Objects.LuaUTypes).disguise
compose = Dash.compose
c_modify = ComposeOperations.modify_argument

function AccessoryV3.componentsArgs.from.dictionary1(
	d: dict<{component}>): componentMap
	
	local keys = Dash.keys(d)
	
	for _, i in next, keys do
		local j = i:split('.')
		local v = d[i]
		d[i] = nil
		d[j] = v
	end
	
	return disguise(d)
end

function AccessoryV3.componentsArgs.from.model1(model: Model): componentMap
	local result = {}
	
	for _, v in next, model:GetChildren() do
		assert(v:IsA('Model'))
		
		local name = v.PrimaryPart and v.PrimaryPart.Name or v.Name
		
		result[name] = result[name] or {}
		
		local component = AccessoryComponent.new(v)
		local reference = component:getReference()
		
		for _, w in next, reference:GetChildren() do
			if not (w:IsA('Weld') or w:IsA('Attachment'))then
				w:Destroy()
			end
		end
		
		reference.Transparency = 1
		
		table.insert(result[name], component)
	end
	
	return AccessoryV3.componentsArgs.from.dictionary1(result)
end

function AccessoryV3.new(
	name: string, 
	components_args: componentMap, 
	keep_states: boolean?): object
	local self: object = Object.from.class(AccessoryV3)
	
	self.name = name;
	self.components = components_args
	self:__constructEvent('attached', 'destroyed')
	
	if not keep_states then
		for _, v in next, self.components do
			for _, w in next, v do
				w.hasMass = false
				w.hasCollision = false
				w:updateModel()
			end
		end
	end
	
	return self
end

function AccessoryV3.attachTo(self: object, parent: Instance)
	local model = Instance.new('Model')
	
	for i, v in next, self.components do
		local part = InstanceUtils.findFirstDescendant(parent, unpack(i))
		
		for _, w in next, v do
			w:attachTo(part, model)
		end
		
	end

	self.model = model
	
	if self.statuses then 
		for _, w in self.statuses do
			w.host = parent
			w:toggle(true)
		end
	end

	model.Parent = parent
	model.Name = self.name
	
	self.__attached:fire(parent)
	
	return model
end

function AccessoryV3.detatch(self: object)
	for _, v in next, self.components do
		for _, w in next, v do
			w:detatch()
		end
	end
end

function AccessoryV3.destroy(self: object)
	self.isDestroyed = true
	for _, v in next, self.components do
		for _, w in next, v do
			w:destroy()
		end
	end
	
	if self.statuses then
		for _, v in self.statuses do
			v:destroy()
		end
	end
	if self.model then
		self.model:Destroy()
	end
	self.__destroyed:fire()
end

function AccessoryV3.clone(self: object)
	local other = {}
	
	for i, v in self.components do
		local j = table.clone(i)
		local w = table.clone(v)
		
		for x,y in w do
			w[x] = y:clone()
		end
		
		other[j] = w
	end
	
	local result = AccessoryV3.new(self.name, other)
	
	result.statuses = self.statuses
	
	if result.statuses then
		for i, v in result.statuses do
			result.statuses[i] = v:clone();
		end
	end
	
	return result
end

AccessoryV3.from.model1 = compose(
	c_modify(AccessoryV3.componentsArgs.from.model1, 2),
	AccessoryV3.new
) :: (name : string, model: Model) -> object

AccessoryV3.from.dictionary1 = compose(
	c_modify(AccessoryV3.componentsArgs.from.dictionary1, 2),
	AccessoryV3.new
) :: (name: string, dictionary: map<string, {component}>) -> object

AccessoryV3.Destroy = AccessoryV3.destroy
AccessoryV3.__index = AccessoryV3
AccessoryV3.className = 'AccessoryV3/Accessory'

module.accessory = AccessoryV3

--#############################################################################################
--#############################################################################################
--#############################################################################################

--[[
export type morph = {
	accessories: {object};
	name: string;
	
	attachTo: (self: morph, parent: Instance) -> ();
	detatch: (self: object) -> ();

	__attached: package<Instance>;
	attached: event<Instance>;
	__destroyed: package<>;
	destroyed: event<>;
} & Object.object_inheritance
  & Destructable.object

Morph = {}

function Morph.new(name: string, accessories: {object}): morph
	local self: morph = Object.from.class(Morph)
	
	self.name = name
	self.accessories = accessories
	self:__constructEvent('attached', 'destroyed')
	
	return self
end

Morph.from = {}

function Morph.from.simple_struct_1(name: string, dict)
	-- main
	local result = {}

	for i, v in next, dict do
		i = type(i) ~= 'table' and {i} or i

		local a = {}

		for _, b in next, v do
			table.insert(a, AccessoryV2.new(b))
		end

		table.insert(
			result, 
			MorphLimbAccessoryCollection.new(
				AccessoryV2Collection.new(a), 
				i
			)
		)
	end

	return Morph.new(result)
end

function Morph.attachTo(self: morph, parent: Instance)
	for _, v in next, self.accessories do
		v:attachTo(parent)
	end
	
	self.__attached:fire(parent)
end

function Morph.destroy(self: morph)
	if not self.isDestroyed then return end
	
	for _, v in next, self.accessories do
		v:destroy()
	end
	
	self.__destroyed:fire()
end

function Morph.detatch(self: morph)
	for _, v in next, self.accessories do
		v:detatch()
	end
end

Morph.Destroy = Morph.destroy
Morph.__index = Morph
Morph.className = 'AccessoryV3/Morph'

module.morph = Morph

--]]
return module
