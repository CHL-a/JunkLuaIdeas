local Object = require('./Object')
local MLA_Collection = require('./@CHL>MorphLimbAccessoryCollection')
local EventPackage = require('./EventPackage')
local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>
type mla_collection = MLA_Collection.object

export type object = {
	collection :{mla_collection};
	isDestroyed: boolean;
	
	clone:(self:object) -> object;
	destroy:(self:object) -> ();
	
	apply:(self:object, Model) -> (); -- {[string]: {Model}}
	
	getMorphLimbCollection: (self:object, breadcrumb: {string}) -> mla_collection?;
	
	attached: EventPackage.event<BasePart?, Instance?>;
	destroyed: EventPackage.event<BasePart?, Instance?>;
} & Object.object_inheritance

local AccessoryCollection = require('./@CHL>AccessoryCollection')
local Accessory = require('./@CHL>Accessory')

Morph = {}
from = {}
insert = table.insert

function Morph.new(morphLimbCollection: {mla_collection}): object
	local self: object = Object.from.class(Morph)
	self.collection = morphLimbCollection
	
	local last = morphLimbCollection[#morphLimbCollection]
	self.attached = last.attached
	self.destroyed = last.destroyed
	
	return self
end

function from.simple_struct_1(dict: map<string | {string}, {Model}>) : object
	-- main
	local result = {}

	for i, v in dict do
		i = type(i) ~= 'table' and {i} or i

		local a = {}

		for _, b in v do
			insert(a, Accessory.new(b))
		end

		insert(
			result, 
			MLA_Collection.new(AccessoryCollection.new(a), i)
		)
	end
	
	return Morph.new(result)
end

function Morph.destroy(self:object)
	
	assert(not self.isDestroyed)
	self.isDestroyed = true
	
	for _, v in self.collection do
		v:destroy()
	end
end

function Morph.clone(self:object)
	
	assert(not self.isDestroyed)
	
	local a = {}
	
	for _, b in self.collection do
		insert(a, b:clone())
	end
	
	return Morph.new(a)
end

function Morph.apply(self:object, model)
	
	-- pre
	assert(not self.isDestroyed)
	assert(typeof(model) == 'Instance' and model:IsA('Model'))

	-- main
	for _, v in self.collection do
		v:apply(model)
	end
end

function Morph.getMorphLimbCollection(self:object, breadcrumb: {string})
	for _, v in self.collection do
		if #v.breadCrumb ~= #breadcrumb then continue end;
		
		local isCorrectMLC = true
		
		for i, w in breadcrumb do
			if w == v.breadCrumb[i] then continue;end
			
			isCorrectMLC = false
			break
		end
		
		if not isCorrectMLC then continue end
		
		return v
	end
end

Morph.from = from

require('./Class').makeProperClass(Morph, '@CHL>Morph')

return Morph
