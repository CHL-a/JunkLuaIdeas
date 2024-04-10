-- a subclass of NevermoreSpring
-- https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua#L98
--[[
	Made to fit around NevermoreSpring
	
	! UPDATED, IDK IF WORKING
--]]

-- TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local SpringInterface = require(Objects.SpringInterface)
local NevermoreSpring = require(Objects.NevermoreSpring)
local Class = require(Objects.Class);

export type object<A> = {
	canSafeSet: boolean;
} & Class.subclass<Object.object>
  & SpringInterface.updatableSpring<A>

-- main
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new<A>(p: A, runtimer: SpringInterface.runtimeFunction?): object<A>
	runtimer = runtimer or SpringInterface.workspaceRuntime
	
	local self: object<A> = Object
		.from
		.simple_object(NevermoreSpring.new(p, runtimer))
		:__inherit(module)
	
	rawset(self, 'canSafeSet', true)
	self.canUpdate = true
	self.canSafeSet = false
	
	return self
end

module.__newindex = function<A>(self: object<A>, i: string, v: any)
	if self.canSafeSet then
		rawset(self, i, v)
	else
		NevermoreSpring.__newindex(self,i,v)
		--disguise(self).__super:__newindex(self, i, v)
	end
end

module.update = SpringInterface.update
module.__index = module
module.className = '@CHL/Spring'

return module
