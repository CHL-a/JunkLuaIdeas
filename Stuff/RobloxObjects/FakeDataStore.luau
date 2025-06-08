--[[
	Specific purpose: to emulate datastores witihn file place. 
	
	THE OBJECT USED CAN NOT SAVE TO ACTUAL ROBLOX DATASTORES.
--]]

local module = {}

--######################################################################################
--######################################################################################
--######################################################################################

local Objects = game:GetService('ReplicatedStorage').Objects
local Object = require(Objects.Object)
local Map = require(Objects["@CHL>Map"])
local Class = require(Objects.Class)

type map<I,V> = Map.simple<I,V>

--######################################################################################
--######################################################################################
--######################################################################################

export type global = {
	data: map<string, any>;
	GetAsync: <A>(self: global, k: string) -> A;
	SetAsync: <A>(self: global, k: string, v: A) -> ();
	UpdateAsync: <A>(self: global, k: string, update: (old: A)->A) -> ();
} & GlobalDataStore
  & Object.object_inheritance

Global = {}

function Global.new(): global
	local self: global = Object.from.class(Global)

	self.data = {}

	return self
end

function Global.GetAsync(self: global, k: string)return self.data[k]end
function Global.SetAsync(self: global, k: string, v)self.data[k]=k end
function Global.UpdateAsync(self:global,k:string,f)self.data[k]=f(self.data[k])end

Class.makeProperClass(Global, '@CHL>FakeDataStore>Global')

module.global = Global

--######################################################################################
--######################################################################################
--######################################################################################

export type normal = {
	
} & DataStore & Class.subclass<global>

Normal = {}

function Normal.new(): normal
	return Global.new():__inherit(Normal)
end

Class.makeProperClass(Normal, '@CHL>FakeDataStore>Normal')
module.normal = Normal

--######################################################################################
--######################################################################################
--######################################################################################

local Pages = require(Objects["@CHL>Pages"])

export type page<A> = {
	list: {A};
	i: number
} & Class.subclass<Pages.page_base<A>>

DataPage = {}

function DataPage.new<A>(l: {A}): page<A>
	local self: page<A> = Pages.base.new():__inherit(DataPage)
	self.list = l
	self.i = 1
	Ordered.latest = self
	return self
end

function DataPage.canProceed<A>(self: page<A>)
	return self.list[self.i] ~= nil
end

function DataPage.proceed<A>(self: page<A>)
	local result = self.list[self.i]
	self.i += 1
	return result
end

Class.makeProperClass(DataPage, '@CHL>FakeDataStore>Page')

module.page = DataPage

--######################################################################################
--######################################################################################
--######################################################################################

export type ordered = {
	GetSortedAsync: <A>(
		self: ordered, 
		is_ascending: boolean?,
		page_size: number?,
		min: A,
		max: A
	)->Pages;
} & OrderedDataStore 
  & Class.subclass<global>

Ordered = {}

function Ordered.new(): normal
	return Global.new():__inherit(Ordered)
end

function Ordered.GetSortedAsync(self: ordered)
	return Ordered.latest
end

Class.makeProperClass(Ordered, '@CHL>FakeDataStore>Ordered')
module.ordered = Ordered

--######################################################################################
--######################################################################################
--######################################################################################

export type service = {
	data_stores: map<string, global>;
	GetDataStore: (self: service, s: string) -> normal;
	GetOrderedDataStore: (self: service, s: string) -> ordered;
} & DataStoreService 
  & Object.object_inheritance

Service = {}

function Service.new(): service
	local self: service = Object.from.class(Service)
	
	self.data_stores = {}
	
	return self
end

function Service.GetDataStore(self: service, s: string)
	self.data_stores[s] = self.data_stores[s] or Normal.new()
	
	return self.data_stores[s]
end

function Service.GetOrderedDataStore(self:service, s)
	self.data_stores[s] = self.data_stores[s] or Ordered.new()
	
	return self.data_stores[s]
end

Class.makeProperClass(Service, '@CHL>FakeDataStore>Service')

module.singleton = Service.new()
module.service = Service

return module
