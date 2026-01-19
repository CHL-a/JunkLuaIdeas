local Destructable = require('./@CHL>Destructable')

-- CLASS
--###################################################################################
--###################################################################################
--###################################################################################

-- connection
type func<a...> = (a...) -> ();

export type connection_type = 'connect' | 'once' | 'wait'

export type connection<T...> = {
	__f: func<T...>;
	connection_type: connection_type;
	
	is_disconnected: boolean;

	disconnect: (self: connection<T...>) -> ();
	Disconnect: (self: connection<T...>) -> ();
}

local connection = {}

disguise = require('./LuaUTypes').disguise

function connection.new<T...>(connection_type: connection_type, f: func<T...>): connection<T...>
	local self: connection<T...> = disguise(setmetatable({}, connection))
	self.__f = f
	self.connection_type = connection_type
	
	return self
end

function connection.disconnect<T...>(self: connection<T...>)
	if self.is_disconnected then return;end
	
	self.is_disconnected = true
end

connection.Disconnect = connection.disconnect
connection.__index = connection

--###################################################################################
--###################################################################################
--###################################################################################

type node<T...> = {
	__prev: node<T...>?;
	__next: node<T...>?;
	__connection: connection<T...>
}

function disconnect_node<T...>(node: node<T...>)
	local node_prev = node.__prev
	local node_next = node.__next
	local is_first = node_prev.first == node
	
	if node_prev then
		if is_first then
			node_prev.first = node_next
		else
			node_prev.__next = node.__next
		end
	end
	
	node.__prev = nil
	node.__next = nil
	
	if node_next then
		node_next.__prev = node_prev
	end
end

--###################################################################################
--###################################################################################
--###################################################################################

-- event
export type event<T...> = {
	first: node<T...>?;
	last: node<T...>?;
	isDestroyed: boolean;
	is_destroyed: boolean;

	__insert: (self:event<T...>, connection_type, func<T...>) -> ();
	connect: (self: event<T...>, responder: func<T...>) -> connection<T...>;
	Connect: (self: event<T...>, responder: func<T...>) -> connection<T...>;
	once: (self: event<T...>, responder: func<T...>) -> connection<T...>;
	Once: (self: event<T...>, responder: func<T...>) -> connection<T...>;
	wait: (self: event<T...>) -> T...;
	Wait: (self: event<T...>) -> T...;
	destroy: (self: event<T...>) -> ()
} 

local event = {}

local Class = require('./Class')

function event.new<T...>(): event<T...>
	local object: event<T...> = disguise(setmetatable({}, event))
	
	return object
end

function event.__tostring()return '(Event)'end

function event.__insert<T...>(self: event<T...>, ev, f)
	assert(not self.isDestroyed, 'Attempting to use destroyed object')

	local node: node<T...> = {
		__connection = connection.new(ev, f),
	}
	
	if not self.first then
		node.__prev = self
		
		self.first = node
		self.last = node
	else
		node.__prev = self.last
		self.last.__next = node
		self.last = node
	end
end

function event.connect<T...>(self: event<T...>, f)
	return self:__insert('connect', f)
end

function event.wait<T...>(self:event<T...>)
	local thread = coroutine.running()
	
	self:__insert('wait', function(...)coroutine.resume(thread,...)end)
	
	return coroutine.yield(thread)
end

function event.once<T...>(self:event<T...>, f)
	return self:__insert('once', f)
end

function event.destroy<T...>(self: event<T...>)
	if self.is_destroyed then return end
	
	self.is_destroyed = true
	self.isDestroyed = true
	
	while self.first do
		disconnect_node(self.first)
	end
	
	self.first = nil
	self.last = nil
end

event.ConnectParallel = Class.unimplemented
event.Connect = event.connect
event.Wait = event.wait
event.Once = event.once
event.Destroy = event.destroy

Class.make_proper_class(event, '@CHL>EventPackage>Event')

--###################################################################################
--###################################################################################
--###################################################################################

-- package
export type package<T...> = {
	event: event<T...>;

	fire: (self:package<T...>, T...) -> ();
} & Destructable.object

local package = {}

function package.new<T...>(): package<T...>
	local object: package<T...> = disguise(setmetatable({}, package))

	object.event = event.new()

	return object
end

function package.__tostring()return '(EventPackage)'end

function package.destroy<T...>(self: package<T...>)
	if self.isDestroyed then return end
	
	self.isDestroyed = true
	
	self.event:destroy()
	self.event = disguise()
end

function package.fire<T...>(self:package<T...>, ...:T...)
	assert(not self.isDestroyed, 'Attempting to use destroyed value.')
	
	local event = self.event
	local current = event.first
	
	while current do
		local connection = current.__connection
		
		if not connection.is_disconnected then
			connection.__f(...)
		end
		
		local temp = current.__next

		if connection.connection_type ~= 'connect' or connection.is_disconnected then
			disconnect_node(current)
		end
		
		current = temp
	end
end

Class.make_proper_class(package, '@CHL>EventPackage')

return package
