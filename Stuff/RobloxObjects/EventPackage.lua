--[[
	Note:
		Does not have threading when using connect with a connection function with 
		yielding properties
--]]


--// TYPES
local Objects = script.Parent

-- aliases
type structFunc<a...> = (a...) -> any?;

-- types of event uses
export type eventSubjectTypes = 'connect' | 'once' | 'wait'

-- object when establishing a connection
export type connection<a...> = {
	__q: queue<a...>;
	__id: number;
	__f: structFunc<a...>;

	disconnect: (self: connection<a...>) -> nil;
} & RBXScriptConnection

type queue<a...> = {
	{
		subject: eventSubjectTypes;
		f: structFunc<a...>;
		id: number
	}
};

-- event object
export type event<a...> = {
	__availibleId: number;
	__queue: queue<a...>;

	__insert: (self:event<a...>, eventSubjectTypes, structFunc<a...>) -> nil;
	connect: (self: event<a...>, responder: structFunc<a...>) -> connection<a...>;
	once: (self: event<a...>,responder: structFunc<a...>) -> connection<a...>;
	wait: (self: event<a...>) -> a...
} & RBXScriptSignal

-- main object
export type package<a...> = {
	event: event<a...>;

	fire: (self:package<a...>, a...) -> nil;
}

-- CLASS
local LuaUTypes = require(Objects.LuaUTypes)
local Class = require(Objects.Class)

disguise = LuaUTypes.disguise

-- connection
local connection = {}
connection.__index = connection

function connection.new<a...>(
	f: structFunc<a...>, id: number, q: queue<a...>): connection<a...>
	local self: connection<a...> = disguise(setmetatable({}, connection))
	self.__id = id;
	self.__f = f
	self.__q = q
	
	return self
end

connection.disconnect = function<a...>(self: connection<a...>)
	for i, v in next, self.__q do
		if v.f == self.__f and v.id == self.__id then
			table.remove(self.__q, i)
			return
		end
	end
end
connection.Disconnect = connection.disconnect

-- event
local event = {}
event.__index = event
function event.new<a...>(): event<a...>
	local object: event<a...> = disguise(setmetatable({}, event))
	object.__availibleId = 0;
	object.__queue = {}
	
	return object
end

event.ConnectParallel = Class.unimplemented

event.__tostring = function()return 'Event'end

event.__insert = function<a...>(self: event<a...>, ev, f)
	self.__availibleId += 1
	table.insert(self.__queue, {
		subject = ev;
		f = f;
		id = self.__availibleId
	})
end

event.connect = function<a...>(self: event<a...>, f)
	self:__insert('connect', f)
	
	return connection.new(f, self.__availibleId, self.__queue)
end
event.Connect = event.connect

event.wait = function<a...>(self:event<a...>)
	local thread = coroutine.running()
	
	self:__insert('wait', function(...)
		coroutine.resume(thread,...)
	end)
	
	return coroutine.yield(thread)
end
event.Wait = event.wait

event.once = function<a...>(self:event<a...>, f)
	self:__insert('once', f)

	return connection.new(f, self.__availibleId, self.__queue)
end
event.Once = event.once

-- package
local package = {}
package.__index = package

package.__tostring = function()return 'EventPackage'end

function package.new<a...>(): package<a...>
	local object: package<a...> = disguise(setmetatable({}, package))
	local event: event<a...> = event.new()
	
	object.event = event
	
	return object
end

package.fire = function<a...>(self:package<a...>, ...:a...)
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

return package
