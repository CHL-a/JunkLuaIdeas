export type node<T> = {
	value: T;
	next: node<T>;
	prev: node<T>;
}

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

local Class = require('./Class')
local Object = require('./Object')
local Iterator = require('./@CHL>Iterator')

export type forward_iterator<T> = {
	current: node<T>;
} & Iterator.simple<node<T>>;

local module = {}
forward_iterator = {}

function forward_iterator.new<T>(node: node<T>): forward_iterator<T>
	local self: forward_iterator<T> = Object.simple.new(forward_iterator)
	
	self.current = node
	
	return self
end

function forward_iterator.can_proceed<T>(self: forward_iterator<T>): node<T>?
	return self.current
end

function forward_iterator.proceed<T>(self: forward_iterator<T>): node<T>
	local result = self.current
	
	self.current = result.next
	
	return result
end

Class.make_proper_class(forward_iterator, '@CHL>DoubleLinkedList>forward_iterator')

module.forward_iterator = forward_iterator

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

export type backward_iterator<T> = forward_iterator<T>

backward_iterator = {}

function backward_iterator.new<T>(node: node<T>): backward_iterator<T>
	local self: backward_iterator<T> = Object.simple.new(backward_iterator)
	
	self.current = node
	
	return self
end

function backward_iterator.proceed<T>(self: backward_iterator<T>): node<T>
	local result = self.current
	
	self.current = result.prev
	
	return result
end

backward_iterator.can_proceed = forward_iterator.can_proceed

Class.make_proper_class(backward_iterator, '@CHL>DoubleLinkedList>backward_iterator')

module.backward_iterator = backward_iterator

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

export type object<T> = {
	first: node<T>;
	last: node<T>;
	size: number;
	
	is_empty: (self: object<T>) -> boolean;
	
	get_forward_iterator: (self: object<T>, at: number?) -> forward_iterator<T>;
	get_backward_iterator: (self: object<T>, at: number?) -> backward_iterator<T>;
	
	node_at: (self: object<T>, index: number) -> node<T>;
	node_insert: (self: object<T>, index: number, node: node<T>) -> ();
	node_insert_last: (object<T>, node<T>) -> ();
	node_remove: (self: object<T>, index: number) -> node<T>;
	node_remove_last: (self: object<T>) -> node<T>;
	
	at: (self: object<T>, index: number) -> T;
	insert: (self: object<T>, index: number, value: T) -> ();
	insert_last: (self: object<T>, value: T) -> ();
	remove: (self: object<T>, index: number) -> T;
	remove_last: (self: object<T>) -> T;
	
	clear: (self: object<T>) -> ();
	destroy: (self: object<T>) -> (); -- non single cyclic objects requires an explicit destroy function otherwise memory leak
}

function module.new<T>(): object<T>
	local self: object<T> = Object.simple.new(module)
	
	self.first = nil
	self.last = nil
	self.size = 0
	
	return self
end

function module.get_forward_iterator<T>(self: object<T>, at: number?): forward_iterator<T>
	return forward_iterator.new(self.first)
end

function module.get_backward_iterator<T>(self: object<T>, at: number?): backward_iterator<T>
	return backward_iterator.new(self.last)
end

function module.node_at<T>(self: object<T>, index: number): node<T>
	local forward_iterator = self:get_forward_iterator()
	
	for i = 2, index do
		if not forward_iterator:can_proceed() then return end
		forward_iterator:proceed()
	end
	
	return forward_iterator.current
end

function module.node_insert<T>(self: object<T>, index: number, node: node<T>)
	if self.size == 0 then
		self.first = node
		self.last = node
	elseif self.first == 1 then
		self.first.prev = node
		node.next = self.first
		self.first = node
	elseif self.size + 1 == index then
		self.last.next = node
		node.prev = self.last
		self.last = node
	else
		local node = self:node_at(index)
		local prev = node.prev
		prev.next = node
		node.prev = prev
	end
	
	self.size += 1
end

function module.node_remove<T>(self: object<T>, index: number): node<T>
	local node = self:node_at(index)
	
	if self.size == 0 then
		return
	elseif self.size == 1 then
		self.first = nil
		self.last = nil
	elseif node == self.first then
		self.first = node.next
		node.prev = nil
	elseif node == self.last then
		self.last = node.prev
		node.next = nil
	elseif node then
		node.prev.next = node.next
		node.next.prev = node.prev
		node.next = nil
		node.prev = nil
	else
		error(`unhandled: no node at i={index}`)
	end
	
	self.size -= 1
	
	return node
end

function module.at<T>(self: object<T>, index: number): T
	local node = self:node_at(index)
	return node and node.value
end

function module.insert<T>(self: object<T>, index: number, value: T)
	local node = {value = value}
	self:node_insert(index, node)
end

function module.remove<T>(self: object<T>, index: number): T
	local node = self:node_remove(index)
	return node and node.value
end

function module.clear<T>(self: object<T>)
	local forward = self:get_forward_iterator()
	
	while forward:can_proceed() do
		local node = forward:proceed()
		node.next = nil
		node.prev = nil
	end
	
	self.first = nil
	self.last = nil
	self.size = 0
end

function module.node_insert_last<T>(self: object<T>, node: node<T>)self:node_insert(self.size + 1, node) end
function module.node_remove_last<T>(self: object<T>)self:node_remove(self.size)end
function module.insert_last<T>(self: object<T>, value: T)self:insert(self.size + 1, value)end
function module.remove_last<T>(self: object<T>)return self:remove(self.size)end
function module.is_empty<T>(self: object<T>)return self.size == 0 end

function module.destroy(self)
	self:clear()
end

Class.make_proper_class(module, '@CHL>DoubleLinkedList')

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

return module
