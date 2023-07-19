local EventPackage = require(script.Parent.EventPackage)

type __any_function = (...any) -> any

type __racer = {
	thread: thread;
	original: __any_function?;
	isFinished: boolean;
}

type __object = {
	racers: {__racer};
	isRunning: boolean;
	timeLimit: number;
	completedRacers: number;
	
	getRacerFromCurrentThread: (self:__object) -> __racer;
	addRacer: (self: __object, ...(__any_function | thread)) -> nil;
	start: (self: __object) -> nil;
	complete: (self:__object, ...any) -> nil;
	reset: (self:__object) -> nil;
	
	concluded: EventPackage.event<>;
	__concluded: EventPackage.package<>;
	racerFinished: EventPackage.event<(__racer,...any)>;
	__racerFinished: EventPackage.package<(__racer,...any)>;
	
}

export type object = __object

local disguise = function<A>(x):A return x end

local module = {}
module.__index = module

module.new = function()
	local self: __object = disguise(setmetatable({}, module))
	
	self.timeLimit = 60
	self.__concluded = EventPackage.new()
	self.concluded = self.__concluded.event
	self.__racerFinished = EventPackage.new()
	self.racerFinished = self.__racerFinished.event
	self.isRunning = false
	self.racers = {}
	
	return self
end

module.addRacer = function(self:__object, ...: __any_function | thread)
	assert(not self.isRunning)
	
	for i = 1, select('#',...) do
		local e = select(i,...)
		local thread

		if type(e) == 'thread'then
			assert(coroutine.status(e) == 'suspended', 'thread args must be suspended')
			thread = e;
		elseif type(e) == 'function' then
			thread = coroutine.create(e)
		else
			error(`bad type: {type(e)}  |  {e}`)
		end

		table.insert(self.racers, {
			thread = thread;
			isFinished = false;
			original = e ~= thread and e or nil;
		} :: __racer)
	end
end

module.getRacerFromCurrentThread = function(self: __object)
	for _, v in next, self.racers do
		if v.thread ~= coroutine.running() then continue end

		return v
	end
end

module.start = function(self:__object)
	-- pre
	assert(not self.isRunning, 'attempting to start a started race')
	
	-- main
	local racers = #self.racers + 1
	
	self:addRacer(function()
		task.wait(self.timeLimit)
		self:complete()
		
		if racers <= self.completedRacers then
			self.__concluded:fire()
		end
	end)
	
	self.isRunning = true
	
	self.completedRacers = 0
	
	for _, v in next, self.racers do coroutine.resume(v.thread)end
end

module.reset = function(self:__object)
	self.isRunning = false;
	self.completedRacers = 0
	table.clear(self.racers)
end

module.complete = function(self:__object, ...: any)
	local racer = self:getRacerFromCurrentThread()
	
	if not racer then return end;
	-- assert(racer, 'Attempting to complete a race with a non competing thread')
	
	racer.isFinished = true
	self.completedRacers += 1
	self.__racerFinished:fire(racer, ...)
	
	if self.completedRacers >= #self.racers - 1 then
		self.__concluded:fire()
	end
end


return module
