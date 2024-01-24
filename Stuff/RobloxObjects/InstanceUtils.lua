--// TYPES
type __module = {
	create: (<A>(class: string, properties: __properties<A>) -> A) | 
		(<A>(class: string) -> (props: __properties<A>) -> A);
	getOrCreate: <A>(
		parent: Instance, 
		name: string, 
		class: __className, 
		properties: __properties<A>?) -> (A, boolean);
	findFirstDescendant: <A>(parent: Instance, ...string) -> A?;
	waitForDescendant: <A>(parent: Instance, ...string) -> A;
	yieldUntilPresent: <A>(parent: A) -> A;
}
export type module = __module

type __className = string;
export type className = __className

type __properties<A> = {[string]: any};
export type properties<A> = __properties<A>

local Objects = script.Parent

local disguise = require(Objects.LuaUTypes).disguise
local TableUtils = require(Objects['@CHL/TableUtils'])
local Dash = require(Objects["@CHL/DashSingular"])

--// MAIN
local module: __module = disguise{}

function create<A>(className: __className, props: __properties<A>?)
	if not props then
		return function(props2: {[string]: any}?)
			return TableUtils.imprint(Instance.new(className), disguise(props2), true)
		end
	end
	
	return create(className)(props)
end

function getOrCreate<A>(
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

		result = create(class, p)
		isNewlyCreated = true
	end

	return result, isNewlyCreated
end

function findFirstDescendant<A>(parent: Instance, ...: string): A?
	Dash.forEachArgs(function(a)
		if not parent then return end;
		parent = parent:FindFirstChild(a)
	end, ...)

	return disguise(parent)
end

function waitForDescendant<A>(parent: Instance, ...: string): A
	Dash.forEachArgs(function(a)
		parent = parent:WaitForChild(a)
	end, ...)

	return disguise(parent)
end

function yieldUntilPresent<A>(parent: A): A
	local p = disguise(parent)

	while not p:IsDescendantOf(game) do p.AncestryChanged:Wait()end

	return parent
end

module.create = create;
module.getOrCreate = getOrCreate
module.findFirstDescendant = findFirstDescendant
module.waitForDescendant = waitForDescendant
module.yieldUntilPresent = yieldUntilPresent

return module
