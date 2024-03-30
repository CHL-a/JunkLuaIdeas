--// TYPE
local Objects = script.Parent

local Destructable = require(Objects["@CHL/Destructable"])
local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object<A> = {
	name: string;
	active: boolean;
	host: A;
	toggle: (self: object<A>, isActive: boolean?) -> nil;
} & Class.subclass<Object.object>
  & Destructable.object

--// MAIN
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new<A>(host: A): object<A>
	local self: object<A> = Object.new():__inherit(module)
	
	self.active = false;
	self.host = host
	self.isDestroyed = false;
	
	-- cool?
	self.name = 'Status'
	
	return self
end

module.destroy = function<A>(self: object<A>)
	self:assertDestruction()
	
	self:toggle(false)
	
	self.isDestroyed = true
end

module.toggle = Class.abstractMethod
module.assertDestruction = Destructable.assertDestruction
module.__index = module
module.className = '@CHL/Status'

return module
