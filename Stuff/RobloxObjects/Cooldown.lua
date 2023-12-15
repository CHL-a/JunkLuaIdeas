--// TYPES
local Objects = script.Parent
type __object = {
	last: number;
	coolDown: number?;
	clockFunction: () -> number;
	
	getDelta: (self:__object) -> number;
	hasCooldownMet: (self: __object, cooldown: number?, shouldNotReset: boolean?) -> boolean;
}

--// MAIN
local module = {}
local SpringInterface = require(Objects.SpringInterface)
local disguise = require(Objects.LuaUTypes).disguise

module.__index = module
module.default = SpringInterface.workspaceRuntime -- needs a replacement

function module.new(cooldown: number?, clockfunction: SpringInterface.runtimeFunction?)
	local self: __object = disguise(setmetatable({}, module))
	
	self.last = 0
	self.coolDown = cooldown
	self.clockFunction = clockfunction or module.default
	
	return self;
end

module.getDelta = function(self: __object)
	return self.clockFunction() - self.last
end

module.hasCooldownMet = function(self:__object, cd: number?, shouldNotReset: boolean?)
	local cooldown = assert(cd or self.coolDown, 'Attempting to use nil cooldown.')
	local result = self:getDelta() < cooldown
	
	if not shouldNotReset then
		self.last = self.clockFunction()
	end
	
	return result
end

return module
