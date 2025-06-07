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

export type data_store = {
	data: map<string, any>;
	GetAsync: <A>(self: data_store, k: string) -> A;
	SetAsync: <A>(self: data_store, k: string, v: A) -> ();
	UpdateAsync: <A>(self: data_store, k: string, update: (old: A)->A) -> ();
} & DataStore & Object.object_inheritance

DataStore = {}

function DataStore.new(): data_store
	local self: data_store = Object.from.class(DataStore)
	
	self.data = {}
	
	return self
end

function DataStore.GetAsync(self: data_store, k: string)return self.data[k]end
function DataStore.SetAsync(self: data_store, k: string, v)self.data[k]=k end
function DataStore.UpdateAsync(self:data_store,k:string,f)self.data[k]=f(self.data[k])end
Class.makeProperClass(DataStore, '@CHL>FakeDataStore>DataStore')
module.data_store = DataStore

--######################################################################################
--######################################################################################
--######################################################################################

export type service = {
	data_stores: map<string, data_store>;
	GetDataStore: (self: service, s: string) -> data_store;
} & DataStoreService 
  & Object.object_inheritance

Service = {}

function Service.new(): service
	local self: service = Object.from.class(Service)
	self.data_stores = {}
	
	return self
end

function Service.GetDataStore(self: service, s: string)
	if self.data_stores[s] then
		return self.data_stores[s]
	end
	
	self.data_stores[s] = DataStore.new()
	
	return self:GetDataStore(s)
end

Class.makeProperClass(Service, '@CHL>FakeDataStore>Service')

module.singleton = Service.new()
module.service = Service

return module
