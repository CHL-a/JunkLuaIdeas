--// TYPES
local Objects = script.Parent
type __object = {
	last: number;
	interval: number?;
	clockFunction: () -> number;
	recorded: {number};
	
	lap: (self:__object) -> number;
	isQuick: (self: __object, interval: number?) -> boolean;
	reset: (self: __object) -> nil;
	lapAndRecord: (self:__object) -> nil;
	clearRecords: (self:__object) -> nil;
	hasQuickTime: (self: __object, recents: number, interval: number?) -> boolean;
}
export type object = __object

--// MAIN
local module = {}
local SpringInterface = require(Objects.SpringInterface)
local disguise = require(Objects.LuaUTypes).disguise

module.__index = module
module.default = SpringInterface.workspaceRuntime -- needs a replacement

function module.new(
	inter: number?, 
	clockfunction: SpringInterface.runtimeFunction?): __object
	local self: __object = disguise(setmetatable({}, module))
	
	self.recorded = {}
	self.last = 0
	self.interval = inter
	self.clockFunction = clockfunction or module.default
	
	return self;
end

module.lap = function(self: __object) return self.clockFunction() - self.last end

module.isQuick = function(self:__object, interval: number?)
	local interval = assert(interval or self.interval, 'Attempting to use nil cooldown.')
	return self:lap() < interval
end

module.reset = function(self:__object) self.last = self.clockFunction()end
module.clearRecords = function(self:__object)table.clear(self.recorded)end

module.lapAndRecord = function(self:__object)
	table.insert(self.recorded, self:lap())
	self:reset()
end

module.hasQuickTime = function(self:__object, recents: number, interval: number?)
	local interval = assert(interval or self.interval, 'Attempting to not use an interval')
	local recorded = self.recorded
	
	for i = 1, recents do
		if recorded[#recorded - i + 1] > interval then
			return false;
		end
	end
	
	return true
end

return module
