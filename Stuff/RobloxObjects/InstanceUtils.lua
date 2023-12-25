--// TYPES
type __module = {
	create: (<A>(class: string, properties: __properties<A>) -> A) | 
		(<A>(class: string) -> (props: __properties<A>) -> A);
	getOrCreate: <A>(
		parent: Instance, 
		name: string, 
		class: __className, 
		properties: __properties<A>?) -> A;
}
export type module = __module

type __className = string;
export type className = __className

type __properties<A> = {[string]: any};
export type properties<A> = __properties<A>

local Objects = script.Parent

local disguise = require(Objects.LuaUTypes).disguise
local TableUtils = require(Objects['@CHL/TableUtils'])

--// MAIN
local module: __module = disguise{}

function create<A>(className: __className, props: __properties<A>?)
	if not props then
		local inst = Instance.new(className)
		
		return function(props2: {[string]: any}?)
			return TableUtils.imprint(inst, disguise(props2), true)
		end
	end
	
	return create(className)(props)
end

module.create = create;

function getOrCreate<A>(
	parent: Instance, 
	name: string, 
	class:__className, 
	properties: __properties<A>?)

	
	local result = parent:FindFirstChild(name)
	
	if not result then
		local p = properties or {}
		p.Parent = parent;
		p.Name = name
		
		result = create(class, p)
	end
	
	return result
end

module.getOrCreate = getOrCreate

return module
