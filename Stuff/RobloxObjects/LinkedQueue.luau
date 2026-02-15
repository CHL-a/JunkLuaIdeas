local Object = require('./Object')
local Class = require('./Class')

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type node<T> = {
	value: T;
	next: node<T>?;
}

local Iterator = require('./@CHL>Iterator')

type simple_iterator<T, U...> = Iterator.simple<T, U...>

export type node_iterator<T> = {
	current: node<T>;
} & simple_iterator<node<T>>

local module = {}

node_iterator = {}

function node_iterator.new<T>(node: node<T>): node_iterator<T>
	local self: node_iterator<T> = Object.simple.new(node_iterator)

	self.current = node

	return self
end

function node_iterator.can_proceed<T>(self: node_iterator<T>) return self.current ~= nil end

function node_iterator.proceed<T>(self: node_iterator<T>): node<T>
	local current = self.current

	self.current = current.next

	return current
end

Class.make_proper_class(node_iterator, '@CHL>LinkedQueue>Node>Iterator')

module.node_iterator = node_iterator

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type value_iterator<T> = {
	node_iterator: node_iterator<T>;
} & simple_iterator<T>

value_iterator = {}

function value_iterator.new<T>(node_iterator: node_iterator<T>): value_iterator<T>
	local self: value_iterator<T> = Object.simple.new(value_iterator)
	
	self.node_iterator = node_iterator
	
	return self
end

function value_iterator.can_proceed<T>(self: value_iterator<T>): boolean return self.node_iterator:can_proceed() end

function value_iterator.proceed<T>(self: value_iterator<T>): T
	return self.node_iterator:proceed().value
end

Class.make_proper_class(value_iterator, '@CHL>LinkedQueue>ValueIterator')

module.value_iterator = value_iterator

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type object<T> = {
	head: node<T>;
	tail: node<T>;
	size: number;
	
	get_node_iterator: (self: object<T>)->node_iterator<T>;
	get_value_iterator: (self: object<T>)->value_iterator<T>;
	enqueue: (self: object<T>, T)->();
	dequeue: (self: object<T>)->T?;
	peek: (self: object<T>)->T?;
	has: (self: object<T>, T)->boolean;
	is_empty: (self: object<T>)->boolean;
	clear: (self: object<T>)->();
}

default = {}

function default.new<T>(): object<T>
	local self: object<T> = Object.simple.new(default)
	
	self.head = nil
	self.tail = nil
	self.size = 0
	
	return self
end

function default.enqueue<T>(self: object<T>, value: T)
	local node = {
		value = value;
		next = nil;
	}
	
	if self.tail then
		self.tail.next = node
	end
	
	self.tail = node
	
	if not self.head then
		self.head = node
	end
	
	self.size += 1
end

function default.dequeue<T>(self: object<T>): T?
	if not self.head then return nil end
	
	local value = self.head.value
	local next_node = self.head.next
	
	self.head = next_node
	
	if not next_node then
		self.tail = nil
	end
	
	self.size -= 1
	
	return value
end

function default.peek<T>(self: object<T>): T? return self.head and self.head.value or nil end
function default.get_node_iterator<T>(self: object<T>): node_iterator<T> return node_iterator.new(self.head) end
function default.get_value_iterator<T>(self: object<T>): value_iterator<T> return value_iterator.new(self:get_node_iterator()) end
function default.is_empty<T>(self: object<T>): boolean return self.head == nil end

function default.has<T>(self: object<T>, value: T): boolean
	local iterator = self:get_value_iterator()
	
	while iterator:can_proceed() do
		local other = iterator:proceed()
		
		if other == value then
			return true
		end
	end
	
	return false
end

function default.clear<T>(self: object<T>)
	self.head = nil
	self.tail = nil
	self.size = 0
end

Class.make_proper_class(default, '@CHL>LinkedQueue>Default')

module.default = default

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

type vague_array = {any}

export type tuple_node = node<vague_array>
export type tuple_node_iterator = node_iterator<vague_array>

export type tuple_value_iterator<T, U...> = {
	node_iterator: tuple_node_iterator;
} & simple_iterator<T, U...>

tuple_value_iterator = {}

function tuple_value_iterator.new<T, U...>(node_iterator: node_iterator<vague_array>): tuple_value_iterator<T, U...>
	local self: tuple_value_iterator<T, U...> = Object.simple.new(tuple_value_iterator)
	self.node_iterator = node_iterator
	return self
end

function tuple_value_iterator.proceed<T, U...>(self: tuple_value_iterator<T, U...>): (T, U...)
	local node = self.node_iterator:proceed()
	return unpack(node.value)
end

tuple_value_iterator.can_proceed = value_iterator.can_proceed


Class.make_proper_class(tuple_value_iterator, '@CHL>LinkedQueue>Tuple>ValueIterator')

module.tuple_value_iterator = tuple_value_iterator

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type tuple_queue<T, U...> = {
	default_queue: object<vague_array>;
	
	get_size: (self: tuple_queue<T, U...>)->number;
	get_node_iterator: (self: tuple_queue<T, U...>)->tuple_node_iterator;
	get_value_iterator: (self: tuple_queue<T, U...>)->tuple_value_iterator<T, U...>;
	enqueue: (self: tuple_queue<T, U...>, T, U...)->();
	dequeue: (self: tuple_queue<T, U...>)->(T, U...)?;
	peek: (self: tuple_queue<T, U...>)->(T, U...)?;
	is_empty: (self: tuple_queue<T, U...>)->boolean;
	clear: (self: tuple_queue<T, U...>)->();
}

local Dash = require('./@CHL>DashSingular')

compose = Dash.compose
tuple_queue = {}

function tuple_queue.new<T, U...>(): tuple_queue<T, U...>
	local self: tuple_queue<T, U...> = Object.simple.new(tuple_queue)
	
	self.default_queue = default.new()
	
	return self
end

function tuple_queue.enqueue<T, U...>(self: tuple_queue<T, U...>, first: T, ...: U...)
	local packed = {first, ...}
	
	self.default_queue:enqueue(packed)
end

function tuple_queue.dequeue<T, U...>(self: tuple_queue<T, U...>): (T, U...)?
	local packed = self.default_queue:dequeue()
	
	if packed then return unpack(packed) end
end

function tuple_queue.peek<T, U...>(self: tuple_queue<T, U...>): (T, U...)?
	local packed = self.default_queue:peek()
	
	if packed then return unpack(packed) end
end

function default_enqueue_call<T, U...>(self: tuple_queue<T, U...>, ...)return self.default_queue, ... end

function tuple_queue.get_value_iterator<T, U...>(self: tuple_queue<T, U...>): tuple_value_iterator<T, U...>
	local node_iterator = self:get_node_iterator()
	
	return tuple_value_iterator.new(node_iterator)
end

function tuple_queue.get_size<T, U...>(self: tuple_queue<T, U...>): number return self.default_queue.size end

tuple_queue.is_empty = compose(default_enqueue_call, default.is_empty)
tuple_queue.clear = compose(default_enqueue_call, default.clear)
tuple_queue.get_node_iterator = compose(default_enqueue_call, default.get_node_iterator)

Class.make_proper_class(tuple_queue, '@CHL>LinkedQueue>Tuple>Queue')

module.tuple_queue = tuple_queue

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

return module
