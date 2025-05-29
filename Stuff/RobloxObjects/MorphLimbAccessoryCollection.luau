local Object = require('./Object')
local AccessoryCollection = require('./@CHL>AccessoryCollection')
local EventPackage = require('./EventPackage')
local InstanceUtils = require('./@CHL>InstanceUtils')

type ac_object = AccessoryCollection.object

export type object = {
	breadCrumb: {string};
	collection: ac_object;
	isDestroyed: boolean;
	
	apply : (self: object, parent: Instance) -> ();
	destroy: (self:object) -> ();
	clone: (self:object) -> object;
	
	attached: EventPackage.event<BasePart?,Instance?>;
	destroyed: EventPackage.event<BasePart?,Instance?>;
} & Object.object_inheritance

local MorphLimbAccessoryCollection = {}

function MorphLimbAccessoryCollection.new(collection: ac_object, breadCrumb: {string})
	
	-- pre
	assert(type(breadCrumb) == 'table')
	for _, v in next, breadCrumb do
		assert(type(v) == 'string')
	end
	
	local self: object = Object.from.class(MorphLimbAccessoryCollection)
	
	self.breadCrumb = breadCrumb;
	self.collection = collection
	self.attached = collection.attached
	self.destroyed = collection.destroyed
	
	return self
end

function MorphLimbAccessoryCollection.apply(self: object, parent)
	-- pre
	assert(not self.isDestroyed)
	assert(typeof(parent) == 'Instance')

	-- main
	local limb = assert(InstanceUtils.findFirstDescendant(parent, unpack(self.breadCrumb)))
	
	return self.collection:attachTo(limb, parent)
end

function MorphLimbAccessoryCollection.destroy(self:object)
	assert(not self.isDestroyed)
	self.collection:destroy()
	self.__super:Destroy()
end

function MorphLimbAccessoryCollection.clone(self:object)
	assert(not self.isDestroyed)
	
	return MorphLimbAccessoryCollection.new(self.collection:clone(),self.breadCrumb)
end

require('./Class').makeProperClass(MorphLimbAccessoryCollection, '@CHL>MorphLimbAccessoryCollection')

return MorphLimbAccessoryCollection
