local Object = require('./Object')
local Class = require('./Class')

export type object<PARAMS...> = {
	func: (PARAMS...) -> ();
	thread: thread;
	
	enqueue: (self: object<PARAMS...>, PARAMS...) -> ();
}

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type array_queue<params...> = {
	queue: {{any}};
} & object<params...>

local module = {}

disguise = require('./LuaUTypes').disguise
array_queue = {}
yield = coroutine.yield
new_thread = task.spawn
resume = task.defer

function array_queue.new<params...>(func: (params...) -> ()): array_queue<params...>
	local self: array_queue<params...> = Object.simple.new(array_queue)
	self.queue = {}
	self.func = func
	
	self.thread = new_thread(function()
		while true do
			if #self.queue == 0 then yield() end
			
			local val = table.remove(self.queue, 1)
			
			self.func(unpack(val))
		end
	end)
	
	return self
end

function array_queue.enqueue<A...>(self: array_queue<A...>, ...: A...)
	table.insert(self.queue, {...})
	
	if #self.queue == 1 then
		resume(self.thread)
	end
end

Class.make_proper_class(array_queue, '@CHL>ResponsiveQueue>ArrayQueue')

module.array_queue = array_queue

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

local LinkedQueue = require('./@CHL>LinkedQueue')

type tuple_queue<T, U...> = LinkedQueue.tuple_queue<T, U...>

export type linked_queue<T, U...> = {
	queue: tuple_queue<T, U...>;
} & object<T, U...>

linked_queue = {}

function linked_queue.new<T, U...>(func: (T, U...) -> ()): linked_queue<T, U...>
	local self: linked_queue<T, U...> = Object.simple.new(linked_queue)
	self.queue = LinkedQueue.tuple_queue.new()
	self.func = func
	
	self.thread = new_thread(function()
		while true do
			local queue = self.queue
			
			if queue:is_empty() then yield() end
			
			self.func(queue:dequeue())
		end
	end)
	
	return self
end

function linked_queue.enqueue<T, U...>(self: linked_queue<T, U...>, first: T, ...: U...): ()
	self.queue:enqueue(first, ...)
	
	if self.queue:get_size() == 1 then
		resume(self.thread)
	end
end

Class.make_proper_class(linked_queue, '@CHL>ResponsiveQueue>LinkedQueue')

module.linked_queue = linked_queue

return module
