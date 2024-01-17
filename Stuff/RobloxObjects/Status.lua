--// TYPE
local Objects = script.Parent
local Destructable = require(Objects["@CHL/Destructable"])

type __object<A> = {
	active: boolean;
	host: A;
	toggle: (self: __object<A>, isActive: boolean?) -> nil;
} & Destructable.object
export type object<A> = __object<A>

--// MAIN
local module = {}

local disguise = require(Objects.LuaUTypes).disguise
local Class = require(Objects.Class)

module.__index = module

function module.new<A>(host: A)
	local self: __object<A> = disguise(setmetatable({}, module))
	self.active = false;
	self.host = host
	self.isDestroyed = false;
	
	return self
end

module.toggle = Class.abstractMethod
module.destroy = function<A>(self: __object<A>)
	self:assertDestruction()
	
	self:toggle(false)
	
	self.isDestroyed = true
end
module.assertDestruction = Destructable.assertDestruction

return module
