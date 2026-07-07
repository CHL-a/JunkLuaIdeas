local Objects = game:GetService('ReplicatedStorage').Objects

local Class = require(Objects.Class)
local FakeDatastore = require(script.Parent["@CHL/FakeDataStore"])
local Interface = require(script.Parent["@CHL/DataStore2Interface"])
local Map = require(Objects["@CHL/Map"])
local TableUtils = require(Objects["@CHL/TableUtils"])

--#########################################################################################
--#########################################################################################
--#########################################################################################

type map<I,V> = Map.simple<I,V>

export type object<A> = {
} & Class.subclass<FakeDatastore.data_store>
  & Interface.object<A>

local module = {}

function module.new<A>(name: string, player: Player)
	local self: object<A> = FakeDatastore.singleton:GetDataStore(name)
		:__inherit(module)
	self.UserId = player.UserId
	self.Name = name
	
	return self
end

function module.Get<A>(self: object<A>, default: A?, no_get_async: boolean?): A
	return self:GetAsync(`{self.Name}/{self.UserId}`) or default
end

function module.Set<A>(self: object<A>, value: A)
	return self:SetAsync(`{self.Name}/{self.UserId}`, value)
end

function module.GetTable<A, I, V>(self: object<A>, default: A): A
	return TableUtils.fill(self:Get(), default)
end

function module.Save<A>(self: object<A>)
end

module.__index = module
module.className = 'FakeDataStore2/object'

return module
