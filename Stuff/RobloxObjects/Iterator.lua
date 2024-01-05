--// TYPES
local Class = require(script.Parent.Class)

type __object<A...> = {
	proceed: (self:__object<A...>) -> A...;
	canProceed: (self:__object<A...>) -> boolean;
}
export type object<A...> = __object<A...>

--// MAIN
local module = {}
local disguise = require(script.Parent.LuaUTypes).disguise

module.__index = module

module.__call = function<A...>(self: __object<A...>)
	if self:canProceed() then
		return self:proceed()
	end
end

module.new = function<A...>()
	return disguise(setmetatable({}, module)) :: __object<A...>
end

module.proceed = Class.abstractMethod
module.canProceed = Class.abstractMethod

return module
