local Objects = script.Parent
local Object = require(Objects.Object)

local InstanceUtils = require('./@CHL>InstanceUtils')

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

local Class = require('./Class')
local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>

export type observer<RemoteMap> = {
	remotes: RemoteMap;
	get: <A>(self: observer<RemoteMap>, name: string, class: string) -> A;
	get_event: (self: observer<RemoteMap>, name: string) -> RemoteEvent;
	get_function: (self: observer<RemoteMap>, name: string) -> RemoteFunction;
} & Object.object_inheritance

export type observer_args = map<string, 'RemoteEvent' | 'RemoteFunction'>

function module.new<A>(map: observer_args): observer<A>
	local self: observer<A> = Object.from.class(module)

	module.construct()

	self.remotes = Proxy

	for i, v in next, map do
		self:get(i, v)
	end

	return self
end

function module.static_get(name: string, class: string)
	return if IsClient 
		then Remotes:WaitForChild(name, 1/0)
		else InstanceUtils.getOrCreate(Remotes, name, class)
end

function module.static_get_event(name: string)return module.static_get(name, 'RemoteEvent')end
function module.static_get_function(name: string)return module.static_get(name, 'RemoteFunction')end

function module.get<A>(self: observer<A>, name: string, class: string)return module.static_get(name, class)end
function module.get_event<A>(self: observer<A>, name: string)return module.static_get_event(name)end
function module.get_function<A>(self: observer<A>, name: string)return module.static_get_function(name)end

Class.makeProperClass(module, '@CHL>RemoteFolder>Observer')

return module
