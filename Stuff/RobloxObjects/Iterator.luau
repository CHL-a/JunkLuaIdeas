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
Class.makeProperClass(module, '@CHL>Iterator')

return module
