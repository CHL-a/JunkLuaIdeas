--// TYPES
local Objects = script.Parent
local EventPackage = require(Objects.EventPackage)

type __object = {
	isOn: boolean;
	flick: (self:__object, toBool: boolean) -> nil;
	flicked: EventPackage.event<boolean>;
	__flicked:  EventPackage.package<boolean>
}
export type object = __object

--// MAIN
local module = {}
local disguise = require(Objects.LuaUTypes).disguise
module.__index = module

function module.new()
	local self: __object = disguise(setmetatable({}, module))
	
	self.isOn = false;
	self.__flicked = EventPackage.new()
	self.flicked = self.__flicked.event
	
	return self
end

module.flick = function(self: __object, b: boolean)
	if b == nil then
		b = not self.isOn
	end
	
	if self.isOn ~= b then
		self.isOn = b;
		self.__flicked:fire(b)
	end
end

return module
