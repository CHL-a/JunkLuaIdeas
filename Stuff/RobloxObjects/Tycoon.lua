local Objects = game.ReplicatedStorage.Objects

local EventPackage = require(Objects.EventPackage)
local Class = require(Objects.Class)

type __object = {
	units: number;
	owner: Player;
	
	collectUnits: (self:__object) -> number;
	addUnits: (self:__object, number) -> nil;
	
	unitMutated: EventPackage.event<number>;
	__unitMutated: EventPackage.package<number>
}
export type object = __object

local disguise = function<A>(x):A return x; end

local module = {}
module.__index = module

module.new = function()
	local self: __object = disguise(setmetatable({}, module))
	
	self.__unitMutated = EventPackage.new()
	self.unitMutated = self.__unitMutated.event
	self.units = 0
	
	return self
end

module.collectUnits = function(self:__object)
	local temp = self.units
	
	self.units = 0
	
	return temp
end

module.addUnits = function(self:__object, n:number)self.units += n;end

return module
