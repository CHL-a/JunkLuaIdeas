-- SPEC
export type object<params...> = {
	iterationFunc: (params...) -> nil;
	queue: {};
	thread: thread;
	enqueue: (self: object<params...>, params...) -> nil;
}

-- CLASS
local ResponsiveQueue = {}
ResponsiveQueue.__index = ResponsiveQueue

function new<params...>(f: (params...) -> nil): object<params...>
	local result = setmetatable({}, ResponsiveQueue)
	local result: object<params...> = result
	
	result.queue = {}
	result.iterationFunc = f
	result.thread = coroutine.create(function()
		while true do
			if #result.queue == 0 then 
				coroutine.yield()
			end

			local val = table.remove(result.queue, 1)
			local b = result.iterationFunc
			
			b(unpack(val))
		end
	end)
	
	coroutine.resume(result.thread)
	
	return result
end
ResponsiveQueue.new = new
ResponsiveQueue.enqueue = function<p...>(self: object<p...>, ...: p...)
	local a = {}
	
	for b = 1, select('#', ...) do
		a[b] = select(b, ...)
	end
	
	table.insert(self.queue, a)
	
	if #self.queue == 1 then
		coroutine.resume(self.thread)
	end
end

return ResponsiveQueue
