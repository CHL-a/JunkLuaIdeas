-- types
local Objects = game.ReplicatedStorage.Objects

local Class = require(Objects.Class)
local DeepValueIterator = require(Objects.DeepValueIterator)

type __object<A> = {} & Class.subclass<DeepValueIterator.object<A>>

-- implementation
local DeepNonTableIterator = {}
DeepNonTableIterator.__index = DeepNonTableIterator

DeepNonTableIterator.new = function<A>(ref)
	local self: __object<A> = Class.inherit(DeepValueIterator.new(ref),DeepNonTableIterator)
	
	return self
end

DeepNonTableIterator.proceed = function<A>(self:__object<A>)
	local value
	
	repeat
		value = self.__super:proceed()
	until type(value) ~= 'table' 
	
	return value
end

return DeepNonTableIterator
