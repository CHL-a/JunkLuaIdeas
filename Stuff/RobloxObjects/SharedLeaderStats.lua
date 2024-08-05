local Objects = script.Parent
local Object = require(Objects.Object)
local Map = require(Objects["@CHL/Map"])
local c_op = require(Objects["@CHL/ComposeOperations"])
local InstanceU = require(Objects["@CHL/InstanceUtils"])

type dict<T> = Map.dictionary<T>

local module = {}

compose = require(Objects["@CHL/DashSingular"]).compose
disguise = require(Objects.LuaUTypes).disguise

export type object<values> = {
	folder: Folder;
	map: dict<string>;
	values: values;
	get_value_inst: <B>(self: object<values>, string)->B
} & Object.object_inheritance

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type observer<V> = {
	can_set: boolean;
	ref: object<V>;
} & Object.object_inheritance

Observer = {}

function Observer.new<V>(r: object<V>): observer<V>
	local self: observer<V> = Object.from.class(Observer)
	rawset(self, 'can_set', true)
	
	self.ref = r
	self.can_set = false
	
	
	
	return self
end

function Observer.destroy<V>(self: observer<V>)
	self.ref = disguise()
	self.__super:destroy()
end
function Observer.__index<V>(self: observer<V>, i: string)
	return 
		if Observer[i] then Observer[i]
		elseif rawget(self,i) then rawget(self, i)
		elseif self.ref.map[i] then self.ref:get_value_inst(i).Value
		else nil
end

function Observer.__newindex<V>(self: observer<V>, i: string, v: any)
	if self.can_set then
		rawset(self, i, v)
	else
		error(`Attempting to set observer: i="{i}", v=({v})`)
	end
end

Observer.className = '@CHL/LeaderStats/Observer/Shared'

module.Observer = Observer

--#####################################################################################
--#####################################################################################
--#####################################################################################

LeaderStats = {}
LeaderStats.from = {}

function LeaderStats.new<values>(folder: Folder, map: dict<string>, ...): object<values>
	local self: object<values> = Object.from.class(LeaderStats)
	
	self.folder = folder
	self.map = map
	self.values = disguise(Observer.new(self))
	
	return self
end

function LeaderStats.get_value_inst<V>(self: object<V>, i: string)
	return self.folder:WaitForChild(i, 1/0)
end

function LeaderStats.from.player<V>(p: Player, m: dict<string>): object<V>
	local f = p:WaitForChild('leaderstats')
	return LeaderStats.new(f, m)
end

LeaderStats.className = '@CHL/LeaderStats/Shared'
LeaderStats.__index = LeaderStats
module.LeaderStats = LeaderStats

return module
