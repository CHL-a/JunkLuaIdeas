local Objects = script.Parent
local lxmTypes = require(Objects.lxm.Types)
local Object = require(Objects.Object)
local Class = require(Objects.Class)
local APIDump = require(Objects["@MaximumADHD/APIDump"])
local TableUtils = require(Objects["@CHL/TableUtils"])

local module = {}

type instance = lxmTypes.VirtualInstance
type dom = lxmTypes.Rbxm
export type ce_param = {
	instance: Instance;
	virtual: instance;
	object: object;
}
export type lp_struct = {
	from: number;
	to: number;
	property: string;
}

export type object = {
	dom: dom;
	instances: {Instance};
	tree: {number};
	later_property_queue: {lp_struct};
	
	get_instances_tree: (self: object) -> {Instance};
	get_instance: (self: object, instance) -> ();
	add_to_lpq: (self: object, number, number, string)->();
	add_to_lpq_by_virtual: (self: object, instance, string)->();
} & Object.object_inheritance

insert = table.insert
t_clone = table.clone

function module.new(dom: dom): object
	local self: object = Object.from.class(module)
	
	self.dom = dom
	self.instances = {}
	self.tree = {}
	self.later_property_queue = {}
	
	for _, v in dom.Tree do insert(self.tree, v.Ref)end
	for _, v in dom.InstanceRefs do self:get_instance(v) end
	
	local queue = t_clone(self.tree)
	
	while #queue > 0 do
		local ref = table.remove(queue, 1)
		local v_i = self.dom.InstanceRefs[ref]
		
		for _, v in v_i.Children do
			insert(queue, v.Ref)
			self.instances[v.Ref].Parent = self.instances[ref]
		end
	end
	
	for _, a in self.later_property_queue do
		self.instances[a.from][a.property] = self.instances[a.to]
	end
	
	return self
end

function module.get_instance(self: object, inst: instance)
	assert(
		module.creation_exceptions, 
		'Expected creation_exceptions, got nil. Set to empty table to silence.'
	)
	
	local ancestry = APIDump.get_ancestry_by_classname(inst.ClassName)
	local p = {
		instance = Instance.new(inst.ClassName);
		virtual = inst;
		object = self
	} :: ce_param
	
	local subclass = assert(APIDump.get_class_by_name(inst.ClassName))
	
	for _, v in ancestry do
		local f = module.creation_exceptions[v]
		
		if f then
			f(p)
		end
	end
	
	local p_inst = p.instance
	TableUtils.imprint(p_inst, p.virtual.Properties, true)
	
	self.instances[inst.Ref] = p_inst
end

function module.add_to_lpq(self: object, f: number, t: number, p: string)
	insert(self.later_property_queue, {
		from = f;
		to = t;
		property = p
	})
end

function module.add_to_lpq_by_virtual(self: object, i: instance, p: string)
	self:add_to_lpq(i.Ref, i.Properties[p], p)
	i.Properties[p] = nil;
end

function module.get_instances_tree(self: object)
	local result = t_clone(self.tree)
	
	for i, v in result do
		result[i] = self.instances[v]
	end
	
	return result
end

module.creation_exceptions = nil

Class.makeProperClass(module, "@CHL/LxmBuilder")

return module
