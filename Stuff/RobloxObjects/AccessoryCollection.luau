local Object = require('./Object')
local AccessoryV2 = require('./@CHL>Accessory')
local EventPackage = require('./EventPackage')

export type object = {
	collection : {AccessoryV2.object};
	isDestroyed: boolean;
	
	attachTo : (self:object, part: BasePart, parent: Instance) -> ();
	clone: (self:object) -> object;
	destroy: (self:object) -> ();
	
	attached: EventPackage.event<BasePart?, Instance?>;
	destroyed: EventPackage.event<BasePart?, Instance?>;
} & Object.object_inheritance

AccessoryCollection = {}

function AccessoryCollection.new(accessoryv2s : {AccessoryV2.object})
	local self: object = Object.from.class(AccessoryCollection)
	
	self.collection = accessoryv2s
	
	local last = accessoryv2s[#accessoryv2s]
	self.attached = last.attached
	self.destroyed = last.destroyed
	
	return self
end

function AccessoryCollection.clone(self:object)
	assert(not self.isDestroyed)
	
	local a = {}
	
	for _, b in self.collection do table.insert(a, b:clone())end
	
	return AccessoryCollection.new(a)
end

function AccessoryCollection.destroy(self:object)
	assert(not self.isDestroyed)
	
	for _, b in self.collection do
		b:destroy()
	end
	
	self.__super:Destroy()
end

function AccessoryCollection.attachTo(self: object, part, parent)
	-- pre
	assert(not self.isDestroyed)
	assert(
		typeof(part) == 'Instance' 
			and part:IsA('BasePart')
			and typeof(parent) == 'Instance',
		`oops:{part}|{parent}`
	)
	
	-- main
	for _, v in self.collection do
		v:attachTo(part, parent)
	end
end

require('./Class').makeProperClass(AccessoryCollection, '@CHL>AccessoryCollection')

return AccessoryCollection
