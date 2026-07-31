local Map = require('./@CHL>Map')
local Class = require('./Class')
local Object = require('./Object')

type dict<T> = Map.dictionary<T>

export type object = {
	data: dict<RBXScriptConnection>;
	
	add: (self: object, index: string, value: RBXScriptConnection, explicit_override: boolean?) -> boolean;
	remove: (self: object, index: string) -> boolean;
	detach_once: (self: object, index: string) -> RBXScriptConnection?;
	destroy: (self: object) -> ();
}

local module = {}

function module.new(): object
	local self: object = Object.simple.new(module)
	
	self.data = {}
	
	return self
end

function module.add(self: object, index: string, value: RBXScriptConnection, explicit_override: boolean?)
	if self.data[index] and not explicit_override then 
		return false 
	end
	
	self.data[index] = value
	
	return true
end

function module.remove(self: object, index: string)
	local connection = self:detach_once(index)
	
	if connection then
		connection:Disconnect()
	end
	
	return not not connection
end

function module.destroy(self: object)
	for _, connection: RBXScriptConnection in self.data do
		connection:Disconnect()
	end
	
	table.clear(self.data)
	self.data = nil
end

function module.detach_once(self: object, index: string)
	local data = self.data
	local connection = data[index]
	
	if connection then
		data[index] = nil
	end
	
	return connection
end

Class.make_proper_class(module, '@CHL>RBXConnectionMap')

return module
