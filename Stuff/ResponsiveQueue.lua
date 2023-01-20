local ResponsiveQueue = {}

function ResponsiveQueue.new<rValues..., params...>(func: (params...) -> rValues...)
	local object = {}
	object.queue = {}

	object.thread = coroutine.create(function()
		while true do
			if #object.queue == 0 then 
				coroutine.yield()
			end

			local val = table.remove(object.queue, 1)

			func(unpack(val))
		end
	end)
	
	object.call = function(...: params...)
		local temp = {}
		
		for i = 1, select('#', ...) do
			temp[i] = select(i, ...)
		end
		
		table.insert(object.queue, temp)
		
		if #object.queue == 1 then
			coroutine.resume(object.thread)
		end
	end
	
	
	return object
end


return ResponsiveQueue
