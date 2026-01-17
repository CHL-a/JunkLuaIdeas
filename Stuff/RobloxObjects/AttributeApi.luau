local Map = require('./@CHL>Map')

type dict<T> = Map.dictionary<T>

export type object = {
	prefix: string;
	instance: Instance;
	
	get_attribute_name: (self: object, suffix: string)->string;
	set: (self: object, suffix: string, value: any)->();
	get: (self: object, suffix: string)->any;
	get_dictionary: (self: object)->dict<any>;
	set_dictionary: (self: object, value: dict<any>)->();
}

local module = {}

local Object = require('./Object')
local Class = require('./Class')

function module.new(instance: Instance, prefix: string): object
	local self = Object.simple.new(module)
	self.instance = instance
	self.prefix = prefix
	return self
end

function module.get_attribute_name(self: object, suffix: string)
	return self.prefix .. suffix
end

function module.get(self: object, suffix)
	return self.instance:GetAttribute(self:get_attribute_name(suffix))
end

function module.set(self: object, suffix, value)
	return self.instance:SetAttribute(self:get_attribute_name(suffix), value)
end

function module.get_dictionary(self: object)
	local result = {}
	
	for i, v in self.instance:GetAttributes() do
		if i:sub(1, #self.prefix) == self.prefix then
			local suffix = i:sub(#self.prefix + 1)
			result[suffix] = v
		end
	end
	
	return result
end

function module.set_dictionary(self: object, value: dict<any>)
	for i, v in value do
		self:set(i, v)
	end
end

Class.make_proper_class(module, '@CHL>AttributeApi')

return module
