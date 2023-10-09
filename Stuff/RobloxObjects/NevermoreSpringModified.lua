-- a subclass of NevermoreSpring
-- https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua#L98

-- type
local SpringInterface = require(script.Parent.SpringInterface)
local NevermoreSpring = require(script.Parent.NevermoreSpring)
local Class = require(script.Parent.Class)

type __object<A> = Class.subclass<SpringInterface.updatableSpring<A>>
export type object<A> = __object<A>

-- main
local module = {}
local disguise = require(script.Parent.LuaUTypes).disguise

module.__index = module

module.new = function<A>(p: A, runtimer: SpringInterface.runtimeFunction?)
	runtimer = runtimer or SpringInterface.workspaceRuntime
	
	local self: __object<A> = disguise(Class.inherit(NevermoreSpring.new(p, runtimer), module))
	rawset(self,'canUpdate',true)
	
	return self
end

module.update = SpringInterface.update

return module
