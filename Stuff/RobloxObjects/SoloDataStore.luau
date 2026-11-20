local module = {}
local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')
local LuaUTypes = require('@game/ReplicatedStorage/Objects/LuaUTypes')
local PluginDeadDrop = require('@game/ReplicatedStorage/Objects/@CHL>PluginDeadDrop')

empty = LuaUTypes.empty

function module.find_folder(): Folder?
	return script.Parent.Parent:FindFirstChild('SoloDataStore')
end

function module.find_bindable(): BindableEvent?
	local folder = module.find_folder()
	
	return folder and folder:FindFirstChild('Gateway')
end

bindable = module.find_bindable()

module.data = nil

if bindable then
	module.data = PluginDeadDrop.from_medium(module.find_folder():GetAttribute('data')) or {}
	
	game:BindToClose(function(reason)
		if not module.data then
			return
		end
		bindable:Fire(module.data)
	end)
else
	module.data = {}
end

--###########################################################################################################################################################################################
--###########################################################################################################################################################################################
--###########################################################################################################################################################################################

local Object = require('@game/ReplicatedStorage/Objects/Object')
local Map = require('@game/ReplicatedStorage/Objects/@CHL>Map')
local Class = require('@game/ReplicatedStorage/Objects/Class')

type map<I,V> = Map.simple<I,V>
type dict<T> = Map.dictionary<T>

--###########################################################################################################################################################################################
--###########################################################################################################################################################################################
--###########################################################################################################################################################################################

export type global = {
	data: dict<any>;
	GetAsync: <A>(self: global, k: string) -> A;
	SetAsync: <A>(self: global, k: string, v: A) -> ();
	UpdateAsync: <A>(self: global, k: string, update: (old: A)->A) -> ();
} & GlobalDataStore

global = {}

function global.new(data: dict<any>?): global
	local self: global = Object.simple.new(global)
	
	self.data = data or {}
	
	return self
end

function global.GetAsync<A>(self: global, k: string): A
	return self.data[k]
end

function global.SetAsync<A>(self: global, k: string, v: A)
	self.data[k] = v
end

function global.UpdateAsync<A>(self: global, k: string, f: (old: A)->A)
	self.data[k] = f(self.data[k])
end

Class.make_proper_class(global, '@CHL>SoloDatastore>Global')

module.global = global

--###########################################################################################################################################################################################
--###########################################################################################################################################################################################
--###########################################################################################################################################################################################
export type service = {
	data_stores: map<string, global>;
	GetDataStore: (self: service, s: string) -> global; -- normal;
	--GetOrderedDataStore: (self: service, s: string) -> ordered;
} & DataStoreService 

service = {}

function service.new(): service
	local self: service = Object.simple.new(service)
	
	self.data_stores = {}
	
	return self
end

function service.GetDataStore(self: service, s: string)
	module.data[s] = module.data[s] or {}
	self.data_stores[s] = self.data_stores[s] or global.new(module.data[s])
	
	return self.data_stores[s]
end

--[[
function service.GetOrderedDataStore(self:service, s)
	self.data_stores[s] = self.data_stores[s] or Ordered.new()
	
	return self.data_stores[s]
end
--]]

Class.make_proper_class(service, '@CHL>SoloDatastore>Service')

module.singleton = service.new() :: service
module.service = service

--###########################################################################################################################################################################################
--###########################################################################################################################################################################################
--###########################################################################################################################################################################################


return module
