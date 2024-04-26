--// TYPES

type __className = string;
export type className = __className

type __properties<A> = {[string]: any};
export type properties<A> = __properties<A>

local Objects = script.Parent

local disguise = require(Objects.LuaUTypes).disguise
local TableUtils = require(Objects['@CHL/TableUtils'])
local Dash = require(Objects["@CHL/DashSingular"])

--// MAIN
local module = {} 

function module.create<A>(className: __className, props: __properties<A>?)
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
	class:__className, 
	properties: __properties<A>?)

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

--###########################################################################################
--###########################################################################################
--###########################################################################################

Weld = {}

function Weld.apply(part0: BasePart, part1: BasePart, c0: CFrame?, c1: CFrame?)
	local result = Instance.new('Weld')
	result.Part0 = part0
	result.Part1 = part1
	result.C0 = c0
	result.C1 = c1
	result.Parent = part0

	return result
end

--###########################################################################################
--###########################################################################################
--###########################################################################################

module.weld = Weld

return module
