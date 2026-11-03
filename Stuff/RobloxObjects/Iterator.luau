--// TYPES
local Object = require('./Object')
local Class = require('./Class')

-- best definition but the parameters are made on the first call
export type iterator_function<Init, U, T...> = (Init, U)->(U, T...)

export type object<A, B...> = {
	proceed: (self: object<A, B...>) -> (A, B...);
	canProceed: (self: object<A, B...>) -> boolean;
	call: (self: object<A, B...>) -> (A, B...);
	__iter: <B>(self: object<A, B...>) -> iterator_function<nil, A, B...>
} & Class.subclass<Object.object>

--// MAIN
--#####################################################################################
--#####################################################################################
--#####################################################################################

local module = {}

disguise = require('./LuaUTypes').disguise

function module.new<A, B...>(): object<A, B...>
	return Object.from.class(module)
		--disguise(setmetatable({}, module)) :: __object<A...>
end

function module.call<A, B...>(self: object<A, B...>)
	if self:canProceed() then
		return disguise(self):proceed()
	end
end

function module.__iter<A, B...>(self: object<A, B...>): iterator_function<nil, A, B...>
	return function(_: nil, last: A, ...: B...): (A, B...)
		return self:call()
	end
end

module.proceed = Class.abstractMethod
module.canProceed = Class.abstractMethod
module.can_proceed = Class.abstractMethod
Class.make_proper_class(module, '@CHL>Iterator')

--###########################################################################################################################################################################
--###########################################################################################################################################################################
--###########################################################################################################################################################################

export type simple<A, B...> = {
	proceed: (self: simple<A, B...>) -> (A, B...);
	can_proceed: (self: simple<A, B...>) -> boolean;
}
simple = {}

function simple.new<A, B...>(): simple<A, B...>
	return Object.simple.new(simple)
end

function simple.__iter<A, B...>(self: simple<A, B...>): iterator_function<nil, A, B...>
	return function(_: nil, last: A, ...: B...): (A, B...)
		if disguise(self):can_proceed() then
			return disguise(self):proceed()
		end
		return disguise()
	end
end

function simple.declare_as(CLASS: any)
	assert(CLASS.can_proceed, 'missing can_proceed function')
	assert(CLASS.proceed, 'missing proceed function')
	
	CLASS.__iter = simple.__iter
end

simple.proceed = Class.abstractMethod
simple.can_proceed = Class.abstractMethod

Class.make_proper_class(simple, '@CHL>Iterator>simple')

module.simple = simple

--###########################################################################################################################################################################
--###########################################################################################################################################################################
--###########################################################################################################################################################################

variants = {}

export type iteration_limitator<A, B...> = {
	iterations: number;
	iterator: simple<A, B...>
} & simple<A, B...>

variants.iteration_limitator = {}

function variants.iteration_limitator.new<A, B...>(iterations: number, iterator: simple<A, B...>): iteration_limitator<A, B...>
	local self: iteration_limitator<A, B...> = Object.simple.new(variants.iteration_limitator)
	
	self.iterations = iterations
	self.iterator = iterator
	
	return self
end

function variants.iteration_limitator.can_proceed<A, B...>(self: iteration_limitator<A, B...>): boolean
	return self.iterations > 0 and self.iterator:can_proceed()
end

function variants.iteration_limitator.proceed<A, B...>(self: iteration_limitator<A, B...>): (A, B...)
	if self:can_proceed() then
		self.iterations -= 1
		return self.iterator:proceed()
	end
end

Class.make_proper_class(variants.iteration_limitator, '@CHL>Iterator>iteration_limitator')

module.variants = variants

--###########################################################################################################################################################################
--###########################################################################################################################################################################
--###########################################################################################################################################################################

return module
