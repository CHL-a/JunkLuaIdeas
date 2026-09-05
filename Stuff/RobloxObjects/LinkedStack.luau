local Object = require('./Object')
local Class = require('./Class')

export type node<T> = {
	value: T;
	next: node<T>?;
}

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type object<T> = {
	top: node<T>?;
	size: number;
	
	push_node: (self: object<T>, node: node<T>) -> ();
	pop_node: (self: object<T>) -> node<T>?;
	peek_node: (self: object<T>) -> node<T>?;
	
	push: (self: object<T>, value: T) -> ();
	pop: (self: object<T>) -> T?;
	peek: (self: object<T>) -> T?;
	is_empty: (self: object<T>) -> boolean;
	clear: (self: object<T>) -> ();
}

local module = {}

function module.new<T>(): object<T>
	local self: object<T> = Object.simple.new(module)
	
	self.top = nil
	self.size = 0
	
	return self
end

function module.push_node<T>(self: object<T>, node: node<T>)
	if not self.top then
		self.top = node
	else
		node.next = self.top
		self.top = node
	end
	
	self.size += 1
end

function module.pop_node<T>(self: object<T>): node<T>?
	if not self.top then
		return nil
	end
	
	local top = self.top
	self.top = top.next
	
	self.size -= 1
	
	return top
end

function module.peek_node<T>(self: object<T>): node<T>?
	return self.top
end

function module.push<T>(self: object<T>, value: T)
	self:push({value = value})
end

function module.pop<T>(self: object<T>): T?
	local node = self:pop_node()
	
	if not node then
		return nil
	end
	
	return node.value
end

function module.peek<T>(self: object<T>): T?
	local node = self:peek_node()
	
	if not node then
		return nil
	end
	
	return node.value
end

function module.is_empty<T>(self: object<T>): boolean
	return self.size == 0
end

function module.clear<T>(self: object<T>)
	self.top = nil
	self.size = 0
end

Class.make_proper_class(module, '@CHL>LinkedStack')

return module
