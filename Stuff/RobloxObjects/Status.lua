--// TYPE
local Objects = script.Parent

local Destructable = require(Objects["@CHL/Destructable"])
local Object = require(Objects.Object)
local Class = require(Objects.Class)
local Dash = require(Objects["@CHL/DashSingular"])

export type object<A> = {
	name: string;
	active: boolean;
	host: A?;
	toggle: (self: object<A>, isActive: boolean?) -> ();
	clone: (self: object<A>) -> object<A>
} & Object.object_inheritance

--// MAIN
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new<A>(host: A?): object<A>
	local self: object<A> = Object.from.class(module)
	
	self.active = false;
	self.host = host
	self.isDestroyed = false;
	
	-- cool?
	self.name = 'Status'
	
	return self
end

function module.destroy<A>(self: object<A>)
	if self.isDestroyed then return end
	
	self:toggle(false)
	
	self.isDestroyed = true
end

function module.clone<A>(self: object<A>)
	local c: object<A> = disguise(Dash.last(self.__supers)).new(self.host)
	
	return c
end

function module.toggle<A>(self: object<A>, b: boolean)
	if b == nil then
		b = not self.active
	end
	
	if b == self.active then return false;end
	
	self.active = b
end

module.assertDestruction = Destructable.assertDestruction
Class.makeProperClass(module, '@CHL/Status')

return module
