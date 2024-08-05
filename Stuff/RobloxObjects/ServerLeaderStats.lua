local Objects = game:GetService('ReplicatedStorage').Objects
local Object = require(Objects.Object)
local SharedLeaderStats = require(Objects['@CHL/SharedLeaderStats'])
local Map = require(Objects["@CHL/Map"])
local InstanceU = require(Objects["@CHL/InstanceUtils"])
local c_op = require(Objects["@CHL/ComposeOperations"])

type dict<T> = Map.dictionary<T>
export type object<T> = SharedLeaderStats.object<T>
export type observer<T> = SharedLeaderStats.observer<T>

local module = {}
disguise = require(Objects.LuaUTypes).disguise
compose = require(Objects["@CHL/DashSingular"]).compose

--#####################################################################################
--#####################################################################################
--#####################################################################################

Observer = {}

function Observer.new<V>(r: object<V>): observer<V>
	return SharedLeaderStats.Observer.new(r):__inherit(Observer)
end

function Observer.__index<V>(self: observer<V>, i: string)
	
	return 
		if Observer[i] then Observer[i]
		elseif rawget(self,i) then rawget(self, i)
		elseif SharedLeaderStats.Observer[i] then SharedLeaderStats.Observer[i]
		elseif self.ref.map[i] then self.ref:get_value_inst(i).Value
		else nil
end

function Observer.__newindex<V>(self: observer<V>, i: string, v: any)
	
	if self.can_set then
		rawset(self, i, v)
	else
		self.ref:get_value_inst(i).Value = v
	end
end

Observer.className = '@CHL/LeaderStats/Observer/Server'

module.Observer = Observer

--#####################################################################################
--#####################################################################################
--#####################################################################################

LeaderStats = {}
LeaderStats.from = {}

function LeaderStats.new<values>(folder: Folder, map: dict<string>)
	local self: object<values> = SharedLeaderStats.LeaderStats.new(folder, map)
		:__inherit(LeaderStats)
	
	disguise(self.values):destroy()
	self.values = disguise(Observer.new(self))

	return self
end

function LeaderStats.from.player<V>(p: Player, map: dict<string>): object<V>
	local f = InstanceU.getOrCreate(p, 'leaderstats', 'Folder')
	return LeaderStats.new(f, map)
end

function LeaderStats.get_value_inst<V>(self: object<V>, i: string)
	return InstanceU.getOrCreate(self.folder, i, self.map[i])
end

LeaderStats.className = '@CHL/LeaderStats/Server'
LeaderStats.__index = LeaderStats
module.LeaderStats = LeaderStats

return module
