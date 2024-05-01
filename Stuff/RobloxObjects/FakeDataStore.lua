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
local Map = require(Objects["@CHL/Map"])

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

DataStore.GetAsync = function(self: data_store, k: string)return self.data[k]end
DataStore.SetAsync = function(self: data_store, k: string, v)self.data[k]=k end
DataStore.UpdateAsync=function(self:data_store,k:string,f)self.data[k]=f(self.data[k])end
DataStore.__index = DataStore
DataStore.className = 'DataStore'
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

Service.GetDataStore = function(self: service, s: string)
	if self.data_stores[s] then
		return self.data_stores[s]
	end
	
	self.data_stores[s] = DataStore.new()
	
	return self:GetDataStore(s)
end

Service.__index = Service
Service.className = 'FakeDataStore/Service'

module.singleton = Service.new()
module.service = Service

return module
