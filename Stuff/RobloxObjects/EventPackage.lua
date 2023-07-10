--[[
	Note:
		Does not have threading when using connect with a connection function with 
		yielding properties
--]]


-- SPECS

-- aliases
type structFunc<a...> = (a...) -> any?;

-- types of event uses
export type eventSubjectTypes = 'connect' | 'once' | 'wait'

-- object when establishing a connection
type __connection<a...> = {
	__q: queue<a...>;
	__id: number;
	__f: structFunc<a...>;
	
	disconnect: (self: __connection<a...>) -> nil;
} & RBXScriptConnection

export type connection<a...> = __connection<a...>

type queue<a...> = {
	{
		subject: eventSubjectTypes;
		f: structFunc<a...>;
		id: number
	}
};

-- event object
type __event<a...> = {
	__availibleId: number;
	__queue: queue<a...>;

	__insert: (self:event<a...>, eventSubjectTypes, structFunc<a...>) -> nil;
	connect: (self: __event<a...>, responder: structFunc<a...>) -> __connection<a...>;
	once: (self: __event<a...>,responder: structFunc<a...>) -> __connection<a...>;
	wait: (self: __event<a...>) -> a...
} & RBXScriptSignal

export type event<a...> = __event<a...>


-- main object
type __package<a...> = {
	event: event<a...>;

	fire: (self:__package<a...>, a...) -> nil;
}

export type package<a...> = __package<a...>

-- CLASS
local LuaUTypes = require(script.Parent.LuaUTypes)

-- connection
local connection = {}
connection.__index = connection

connection.new = function<a...>(f: structFunc<a...>, id: number, q: queue<a...>)
	local object: __connection<a...> = LuaUTypes.disguise(setmetatable({}, connection))
	object.__id = id;
	object.__f = f
	object.__q = q
	
	return object
end

connection.disconnect = function<a...>(self:__connection<a...>)
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
event.new = function<a...>()
	local object: __event<a...> = LuaUTypes.disguise(setmetatable({}, event))
	object.__availibleId = 0;
	object.__queue = {}
	
	return object
end

event.ConnectParallel = function()error('unimplemented')end

event.__insert = function<a...>(self: __event<a...>, ev, f)
	self.__availibleId += 1
	table.insert(self.__queue, {
		subject = ev;
		f = f;
		id = self.__availibleId
	})
end

event.connect = function<a...>(self: __event<a...>, f)
	self:__insert('connect', f)
	
	return connection.new(f, self.__availibleId, self.__queue)
end
event.Connect = event.connect

event.wait = function<a...>(self:__event<a...>)
	local thread = coroutine.running()
	
	self:__insert('wait', function(...)
		coroutine.resume(thread,...)
	end)
	
	return coroutine.yield(thread)
end
event.Wait = event.wait

event.once = function<a...>(self:__event<a...>, f)
	self:__insert('once', f)

	return connection.new(f, self.__availibleId, self.__queue)
end
event.Once = event.once

-- package
local package = {}
package.__index = package

package.new = function<a...>()
	local object: __package<a...> = LuaUTypes.disguise(setmetatable({}, package))
	local event: __event<a...> = event.new()
	
	object.event = event
	
	return object
end

package.fire = function<a...>(self:__package<a...>, ...:a...)
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
