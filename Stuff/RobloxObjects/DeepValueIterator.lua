-- types
local Objects = game.ReplicatedStorage.Objects

local Class = require(Objects.Class)
local Iterator = require(Objects.Iterator)
local DeepIndexIterator = require(Objects.DeepIndexIterator)

type __object<A> = {
	iIterator: DeepIndexIterator.object<any>;
} & Class.subclass<Iterator.object<A>>
export type object<A> = __object<A>

-- implementation
local DeepValueIterator = {}
DeepValueIterator.__index = DeepValueIterator

DeepValueIterator.new = function<A>(ref)
	local self: __object<A> = Class.inherit(Iterator.new(),DeepValueIterator)
	self.iIterator = DeepIndexIterator.new(ref)
	
	return self
end

DeepValueIterator.canProceed = function<A>(self:__object<A>)
	return self.iIterator:canProceed()
end

DeepValueIterator.proceed = function<A>(self:__object<A>)
	local val = self.iIterator:proceed()
	
	if #val == 0 then return;end
	return self.iIterator:getValue()
end

return DeepValueIterator
