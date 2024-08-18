--// TYPES
local Objects = script.Parent
local Map = require(Objects["@CHL/Map"])

export type className = string
export type properties<A> = Map.dictionary<any>

local TableUtils = require(Objects['@CHL/TableUtils'])
local Dash = require(Objects["@CHL/DashSingular"])

--// MAIN
local module = {} 

isClient = game:GetService('RunService'):IsClient()
disguise = require(Objects.LuaUTypes).disguise

function module.create<A>(className: className, props: properties<A>?)
	if not props then
		return function(props2: {[string]: any}?)
			return TableUtils.imprint(Instance.new(className), disguise(props2), true)
		end
	end
	
	return module.create(className)(props)
end

function module.getOrCreate<A>(
	parent: Instance, 
	name: string, 
	class: className, 
	properties: properties<A>?)

	local result = parent:FindFirstChild(name)
	local isNewlyCreated = false

	if not result then
		local p = properties or {}
		p.Parent = parent;
		p.Name = name

		result = module.create(class, p)
		isNewlyCreated = true
	end

	return result, isNewlyCreated
end

function module.findFirstDescendant<A>(parent: Instance, ...: string): A?
	Dash.forEachArgs(function(a)
		if not parent then return end;
		parent = parent:FindFirstChild(a)
	end, ...)

	return disguise(parent)
end

function module.waitForDescendant<A>(parent: Instance, ...: string): A
	Dash.forEachArgs(function(a)
		parent = parent:WaitForChild(a)
	end, ...)

	return disguise(parent)
end

function module.yieldUntilPresent<A>(parent: A): A
	local p = disguise(parent)

	while not p:IsDescendantOf(game) do p.AncestryChanged:Wait()end

	return parent
end

function module.getOrClone<T>(parent: Instance, target: T): T
	local result = parent:FindFirstChild(disguise(target).Name)
	
	if not result then
		result = disguise(target):Clone()
		result.Parent = parent
	end
	
	return result
end

--[[
	Returns an instance,
		if runtime is client, parent will wait for child of name,
		otherwise, it will create from getOrCreate
--]]
function module.assumeObject1<T>(parent: Instance, 
	name: string, 
	class: className, 
	properties:  properties<T>?): T
	
	return isClient 
		and disguise(parent):WaitForChild(name, 1/0)
		or module.getOrCreate(parent, name, class, properties)
end

--###########################################################################################
--###########################################################################################
--###########################################################################################

Weld = {}

function Weld.apply(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
	local result = Instance.new('Weld')
	result.Part0 = part0
	result.Part1 = part1
	result.C0 = c0 or part0.CFrame:Inverse() * part1.CFrame
	result.C1 = c1 or CFrame.identity
	result.Parent = part0

	return result
end

--###########################################################################################
--###########################################################################################
--###########################################################################################

module.weld = Weld

return module
