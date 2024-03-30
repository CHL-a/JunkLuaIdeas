--// TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object<A...> = {
	proceed: (self: object<A...>) -> A...;
	canProceed: (self: object<A...>) -> boolean;
	call: (self: object<A...>) -> A...;
} & Class.subclass<Object.object>

--// MAIN
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new<A...>(): object<A...>
	return Object.new():__inherit(module)
		--disguise(setmetatable({}, module)) :: __object<A...>
end

module.call = function<A...>(self: object<A...>)
	if self:canProceed() then
		return self:proceed()
	end
end

module.proceed = Class.abstractMethod
module.canProceed = Class.abstractMethod
module.__index = module
module.className = '@CHL/Iterator'

return module
