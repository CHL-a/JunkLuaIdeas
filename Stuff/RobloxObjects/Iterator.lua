local Class = require(game.ReplicatedStorage.Objects.Class)

type __object<A...> = {
	proceed: (self:__object<A...>) -> A...;
	canProceed: (self:__object<A...>) -> boolean;
}
export type object<A...> = __object<A...>

local disguise = function<A>(x): A return x; end

local module = {}
module.__index = module
module.__call = function<A...>(self: __object<A...>)
	assert(self:canProceed(), 'unable to proceed')
	
	return self:proceed()
end

module.new = function<A...>()
	return disguise(setmetatable({}, module)) :: __object<A...>
end

module.proceed = function<A...>(self:__object<A...>)
	error('Attempting to use an abstract method')
end

module.canProceed = function<A...>(self:__object<A...>)
	error('Attempting to use an abstract method')
end

return module
