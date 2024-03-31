-- TYPE
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object<params...> = {
	queue: {{any}};
	func: (params...) -> ();
	thread: thread;
	
	call: (self: object<params...>, params...) -> ();
} & Class.subclass<Object.object>

-- MAIN
local ResponsiveQueue = {}

disguise = require(Objects.LuaUTypes).disguise

function ResponsiveQueue.new<params...>(func: (params...) -> ())
	local self: object<params...> = Object.new():__inherit(ResponsiveQueue)
	self.queue = {}
	self.func = func
	
	self.thread = coroutine.create(function()
		while true do
			if #self.queue == 0 then 
				coroutine.yield()
			end

			local val = table.remove(self.queue, 1)
			
			self.func(unpack(val))
		end
	end)
	
	return self
end

ResponsiveQueue.call = function<A...>(self: object<A...>, ...: A...)
	local temp = {disguise(...)}

	table.insert(self.queue, temp)

	if #self.queue == 1 then
		coroutine.resume(self.thread)
	end
end

ResponsiveQueue.__index = ResponsiveQueue
ResponsiveQueue.className = 'ResponsiveQueue'

return ResponsiveQueue
