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
export type connection = {
	disconnect: () -> nil;
}

-- event object
export type event<a...> = {
	connect: (responder: structFunc<a...>) -> connection;
	once: (responder: structFunc<a...>) -> connection;
	wait: () -> a...
}

type queue<a...> = {
	{
		subject: eventSubjectTypes;
		f: structFunc<a...>;
		id: number
	}
};

-- main object
export type eventPackage<a...> = {
	id: number;
	event: event<a...>;
	queue: queue<a...>;

	insert: (eventSubjectTypes, structFunc<a...>) -> nil;
	fire: (a...) -> nil;
}

-- CLASS
local EventPackage = {}


function EventPackage.new<a...>()
	local object: eventPackage<a...>
	local event: event<a...>
	
	-- object states
	local queue: queue<a...> = {}
	
	-- methods
	local function insert(ev: eventSubjectTypes, f: structFunc<a...>) 
		table.insert(queue, {
			subject = ev;
			f = f;
			id = object.id
		})
	end
	
	local function fire(...: a...)
		local i = 1;

		while i <= #queue do
			local v = queue[i]

			-- v.f(...)
			-- ^ bruh

			local f: structFunc<a...> = v.f
			f(...)

			if v.subject ~= 'connect' then
				table.remove(queue, i)
				i -= 1
			end

			i += 1
		end
	end
	
	-- event
	
	-- event methods
	local function createConnection(f, id)
		local result: connection = {
			disconnect = function()
				for i, v in next, queue do
					if v.f == f and v.id == id then
						table.remove(queue, i)
						return
					end
				end

				error('disconnected already initiated')
			end,
		}
		
		return result
	end
	
	local function getConnector(eventType: eventSubjectTypes)
		return function(f: structFunc<a...>)
			object.id += 1
			insert(eventType, f)
			
			return createConnection(f,object.id)
		end
	end
	
	local function eWait(): a...
		object.id += 1
		
		local thread = coroutine.running()
		
		object.insert('wait', function(...: a...)
			coroutine.resume(thread, ...)
		end)

		return coroutine.yield(thread)
	end
	
	event = {
		connect = getConnector('connect');
		once = getConnector('once');
		wait = eWait;
	}
	
	object = {
		id = 0;
		queue = queue;

		event = event;
		fire = fire,
		insert = insert
	}

	return object
end



return EventPackage