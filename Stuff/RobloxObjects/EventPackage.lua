local Objects = script.Parent
local Destructable = require(Objects["@CHL/Destructable"])

-- CLASS
--###################################################################################
--###################################################################################
--###################################################################################

-- connection
type structFunc<a...> = (a...) -> ();

export type eventSubjectTypes = 'connect' | 'once' | 'wait'

export type connection<a...> = {
	__q: queue<a...>;
	__id: number;
	__f: structFunc<a...>;
	__is_disconnected: boolean;

	disconnect: (self: connection<a...>) -> ();
} & RBXScriptConnection

local connection = {}

disguise = require(Objects.LuaUTypes).disguise

function connection.new<a...>(
	f: structFunc<a...>, id: number, q: queue<a...>): connection<a...>
	local self: connection<a...> = disguise(setmetatable({}, connection))
	self.__id = id;
	self.__f = f
	self.__q = q
	
	return self
end

function connection.disconnect<a...>(self: connection<a...>)
	if self.__is_disconnected then return;end
	
	for i, v in next, self.__q do
		if v.f == self.__f and v.id == self.__id then
			table.remove(self.__q, i)
			return
		end
	end
	
	self.__is_disconnected = true
end

connection.Disconnect = connection.disconnect
connection.__index = connection

--###################################################################################
--###################################################################################
--###################################################################################

-- event
type queue<a...> = {
	{
		subject: eventSubjectTypes;
		f: structFunc<a...>;
		id: number
	}
};

export type event<a...> = {
	__availibleId: number;
	__queue: queue<a...>;
	isDestroyed: boolean;

	__insert: (self:event<a...>, eventSubjectTypes, structFunc<a...>) -> ();
	connect: (self: event<a...>, responder: structFunc<a...>) -> connection<a...>;
	once: (self: event<a...>,responder: structFunc<a...>) -> connection<a...>;
	wait: (self: event<a...>) -> a...;
} & RBXScriptSignal

local event = {}

local Class = require(Objects.Class)

function event.new<a...>(): event<a...>
	local object: event<a...> = disguise(setmetatable({}, event))
	object.__availibleId = 0;
	object.__queue = {}
	
	return object
end

function event.__tostring()return '(Event)'end

function event.__insert<a...>(self: event<a...>, ev, f)
	assert(not self.isDestroyed, 'Attempting to use destroyed object')
	
	self.__availibleId += 1
	table.insert(self.__queue, {
		subject = ev;
		f = f;
		id = self.__availibleId
	})
end

function event.connect<a...>(self: event<a...>, f)
	self:__insert('connect', f)
	
	return connection.new(f, self.__availibleId, self.__queue)
end

function event.wait<a...>(self:event<a...>)
	local thread = coroutine.running()
	
	self:__insert('wait', function(...)
		coroutine.resume(thread,...)
	end)
	
	return coroutine.yield(thread)
end

function event.once<a...>(self:event<a...>, f)
	self:__insert('once', f)

	return connection.new(f, self.__availibleId, self.__queue)
end

event.ConnectParallel = Class.unimplemented
event.Connect = event.connect
event.Wait = event.wait
event.Once = event.once
event.__index = event

--###################################################################################
--###################################################################################
--###################################################################################

-- package
export type package<a...> = {
	event: event<a...>;

	fire: (self:package<a...>, a...) -> ();
} & Destructable.object

local package = {}

function package.new<a...>(): package<a...>
	local object: package<a...> = disguise(setmetatable({}, package))

	object.event = event.new()

	return object
end

function package.__tostring()return '(EventPackage)'end


function package.destroy<a...>(self: package<a...>)
	if self.isDestroyed then return end
	
	self.isDestroyed = true
	self.event.isDestroyed = true
	self.event = disguise()
end

function package.fire<a...>(self:package<a...>, ...:a...)
	assert(not self.isDestroyed, 'Attempting to use destroyed value.')
	
	local i = 1
	local q = self.event.__queue
	
	while i <= #q do
		local v = q[i]
		
		v.f(...)
		
		if v.subject ~= 'connect' then
			table.remove(q, i)
			i -= 1
		end
		
		i += 1
	end
end

package.__index = package

return package
