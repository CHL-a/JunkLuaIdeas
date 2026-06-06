local Objects = script.Parent
local Object = require(Objects.Object)

local InstanceUtils = require('./@CHL>InstanceUtils')

local module = {}

is_client = game:GetService('RunService'):IsClient()
ReplicatedStorage = game:GetService('ReplicatedStorage')

Remotes = nil
Proxy = nil;

function module.construct()
	if Remotes then return end

	Remotes = if is_client 
		then ReplicatedStorage:WaitForChild('Remotes', 1/0)
		else InstanceUtils.get_or_create(ReplicatedStorage, 'Remotes', 'Folder')

	Proxy = Proxy or setmetatable({}, {__index = function(_, i: string)
		return Remotes:FindFirstChild(i)
	end,})
end

--####################################################################################
--####################################################################################
--####################################################################################

local Class = require('./Class')
local Map = require('./@CHL>Map')
local PromiseTypes = require('./@CHL>PromiseTypes')
local Promise = PromiseTypes.modified.get()

type promise<T...> = PromiseTypes.modified_object<T...>
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
	module.construct()
	return if is_client
		then Remotes:WaitForChild(name, 1/0)
		else InstanceUtils.get_or_create(Remotes, name, class)
end

function module.static_get_event(name: string):RemoteEvent return module.static_get(name, 'RemoteEvent')end
function module.static_get_function(name: string):RemoteFunction return module.static_get(name, 'RemoteFunction')end

function module.get<A>(self: observer<A>, name: string, class: string)return module.static_get(name, class)end
function module.get_event<A>(self: observer<A>, name: string)return module.static_get_event(name)end
function module.get_function<A>(self: observer<A>, name: string)return module.static_get_function(name)end

function module.promisefy_invoke_server<T>(remote_function: RemoteFunction, ...): promise<T>
	local args = {...}
	return Promise.new(function(
		resolve: (...any) -> (...any), 
		reject: (...any) -> (...any), 
		on_cancel: (abortHandler: ((...any) -> (...any))?) -> boolean)
		
		local result = remote_function:InvokeServer(unpack(args))
		
		resolve(result)
	end)
end

-- involves using deprecated InvokeClient, it is by nature, can yield forever
function module.promisefy_invoke_client<T>(remote_function: RemoteFunction, ...): promise<T>
	local args = {...}
	return Promise.new(function(
		resolve: (...any) -> (...any), 
		reject: (...any) -> (...any), 
		on_cancel: (abortHandler: ((...any) -> (...any))?) -> boolean)
		
		local result = remote_function:InvokeClient(unpack(args))
		
		resolve(result)
	end)
end

Class.make_proper_class(module, '@CHL>RemoteFolder>Observer')

--####################################################################################
--####################################################################################
--####################################################################################

export type client_invoker<T...> = {
	requester: RemoteEvent;
	responder: RemoteEvent;
	timeout: number?;
	connection: RBXScriptConnection;
	promises: map<number, promised_struct<T...>>;
	callback: (...any) -> ...any;
	index: number;
	
	get_availible_index: (self: client_invoker<T...>)->number;
	invoke: <U...>(self: client_invoker<(T...)>, Player, U...)->promise<T...>;
	set_responder: (self: client_invoker<T...>, new_responder: RemoteEvent)->();
	set_requester: (self: client_invoker<T...>, new_responder: RemoteEvent)->();
	set_callback: (self: client_invoker<T...>, new_callback: (...any) -> ...any)->();
}

export type promised_struct<T...> = {
	promise: promise<T...>;
	from: Player;
}

ClientInvoker = {}
empty = require('./LuaUTypes').empty

function ClientInvoker.new<T...>(requester: RemoteEvent, responder: RemoteEvent?)
	local responder = responder or requester
	
	local self: client_invoker<T...> = Object.simple.new(ClientInvoker)
	
	self.index = 1
	self.promises = {}
	self.requester = requester
	self:set_responder(responder)
	
	return self
end

function ClientInvoker.get_availible_index<T...>(self: client_invoker<T...>): number
	local result = self.index
	
	self.index += 1
	
	return result
end

function ClientInvoker.set_responder<T...>(self: client_invoker<T...>, new_responder: RemoteEvent)
	self.responder = new_responder
	
	if self.connection then self.connection:Disconnect() end
	
	if not is_client then
		self.connection = self.responder.OnServerEvent:Connect(function(player: Player, index: number, ...)
			local struct = self.promises[index]
			
			if not (struct and struct.from == player) then return;end
			
			struct.promise:resolve(...)
			self.promises[index] = nil
		end)
	end
end

function ClientInvoker.set_requester<T...>(self: client_invoker<T...>, new_requester: RemoteEvent)
	self.requester = new_requester
	
	if is_client then
		if not self.callback then
			warn('no callback, refused to set requester')
			return
		end
		
		if self.connection then self.connection:Disconnect() end
		
		self.connection = self.requester.OnClientEvent:Connect(function(index: number, ...)
			local results = {self.callback(...)}
			
			self.responder:FireServer(index, unpack(results))
		end)
	end
end

function ClientInvoker.set_callback<T...>(self: client_invoker<T...>, new_callback: (...any) -> ...any)
	self.callback = new_callback
	
	self:set_requester(self.requester)
end

function ClientInvoker.invoke<T...>(self: client_invoker<T...>, player: Player, ...): promise<T...>
	local result: promise<T...> = Promise.new(empty)
	
	if self.timeout then
		result = result:timeout(self.timeout)
	end
	
	local index = self:get_availible_index()
	
	self.promises[index] = {
		promise = result;
		from = player;
	}
	
	self.requester:FireClient(player, index, ...)
	
	return result
end

ClientInvoker.from = {}

function ClientInvoker.from.double_name<T...>(name_1: string, name_2: string): client_invoker<T...>
	local remote_1 = module.static_get_event(name_1)
	local remote_2 = module.static_get_event(name_2)
	
	return ClientInvoker.new(remote_1, remote_2)
end

function ClientInvoker.from.single_name<T...>(name: string): client_invoker<T...>
	local remote_1 = module.static_get_event(name)
	
	return ClientInvoker.new(remote_1)
end

Class.make_proper_class(ClientInvoker, '@CHL>RemoteFolder>ClientInvoker')

module.client_invoker = ClientInvoker

--####################################################################################
--####################################################################################
--####################################################################################

return module
