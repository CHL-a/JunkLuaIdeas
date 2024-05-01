local Objects = script.Parent
local Object = require(Objects.Object)

local InstanceUtils = require(Objects["@CHL/InstanceUtils"])

local module = {}

IsClient = game:GetService('RunService'):IsClient()
ReplicatedStorage = game:GetService('ReplicatedStorage')

Remotes = nil
Proxy = nil;

function module.construct()
	if Remotes then return end

	Remotes = if IsClient 
		then ReplicatedStorage:WaitForChild('Remotes', 1/0)
		else InstanceUtils.getOrCreate(ReplicatedStorage, 'Remotes', 'Folder')

	Proxy = Proxy or setmetatable({}, {__index = function(_, i: string)
		return Remotes:FindFirstChild(i)
	end,})
end

--####################################################################################
--####################################################################################
--####################################################################################

local Map = require(Objects["@CHL/Map"])

type map<I,V> = Map.simple<I,V>

export type observer<RemoteMap> = {
	remotes: RemoteMap;
} & Object.object_inheritance

export type observer_args = map<string, 'RemoteEvent' | 'RemoteFunction'>

function module.new<A>(map: observer_args): observer<A>
	local self: observer<A> = Object.from.class(module)
	
	module.construct()
	
	self.remotes = Proxy
	
	for i, v in next, map do
		if IsClient then
			Remotes:WaitForChild(i)
			continue
		end
		
		InstanceUtils.getOrCreate(Remotes, i, v)
	end
	
	return self
end

module.__index = module
module.className = '@CHL/RemoteFolder/Observer'

return module
