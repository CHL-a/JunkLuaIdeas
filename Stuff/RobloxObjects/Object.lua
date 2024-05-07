-- TYPES
local Objects = script.Parent
local Class = require(Objects.Class)
local Destructable = require(Objects["@CHL/Destructable"])

export type object = {-- typeof(setmetatable({}, module))
	className: string;
	__event_names: {string};
	
	getAncestry: (self: object) -> {string};
	__inherit: <A>(self: object, Class: any) -> A;
	__constructEvent: (self: object, ...string) -> ();
	isA: (self: object, className: string) -> boolean;
	isClass: (self: object, C: any) -> boolean;
	hasClass: (self: object, C: any) -> boolean;
	add: <A, B>(self: object, A) -> B;
	sub: <A, B>(self: object, A) -> B;
	mul: <A, B>(self: object, A) -> B;
	div: <A, B>(self: object, A) -> B;
	mod: <A, B>(self: object, A) -> B;
	pow: <A, B>(self: object, A) -> B;
	idiv: <A, B>(self: object, A) -> B;
	eq: <A>(self: object, A) -> boolean;
	lt: <A>(self: object, A) -> boolean;
	le: <A>(self: object, A) -> boolean;
	concat: <A, B>(self: object, A) -> B;
	len: (self: object) -> number;
	call: <A..., B...>(self: object, A...) -> B...;
	toString: <A...>(self: object, A...) -> string;
} & Destructable.object

export type object_inheritance = Class.subclass<object>

type method<self, P..., R...> = (self: self, P...) -> (R...)
type binaryMethod = method<(any), (any)>
type relationalMethod = method<(any), (boolean)>

-- MAIN
local module = {}

local LuaUTypes = require(Objects.LuaUTypes)
local EventPackage = require(Objects.EventPackage)

disguise = LuaUTypes.disguise
unimplemented = disguise(Class.unimplemented)
insert = table.insert
from = {}

function proxyCall(s: string)
	return function(self: object, ...)
		return disguise(self)[s](self, ...)
	end
end

function module.new(): object return from.rawStruct{}end

function from.rawStruct(t): object
	local self: object = disguise(setmetatable(t, module))
	disguise(self).__supers = {}
	self.__event_names = {}
	return self
end

function from.simple_object(o): object
	local C = getmetatable(o)
	rawset(o, '__supers', {})
	setmetatable(o, module)
	return (o::object):__inherit(C)
end

function from.class<A>(CLASS): A
	return module.new():__inherit(CLASS)
end

function module.__constructEvent(self: object, ...: string): ()
	local __s = disguise(self)
	for i = 1, select('#', ...) do
		local s = select(i, ...)
		local t = `__{s}`
		__s[t] = EventPackage.new()
		__s[s] = __s[t].event
		insert(self.__event_names, s)
	end
end

function module.isA(self: object, className: string)
	local supers = disguise(self).__supers
	
	for _, v in next, supers do
		if v.className == className then
			return true
		end
	end
	
	return false
end

function module.getAncestry(self: object)
	local result = {}
	local supers = disguise(self).__supers
	
	if supers then
		for i = 1, #supers do
			local v = supers[i]
			
			if typeof(v) == 'table' then
				insert(result, v.className)
			else
				insert(result, '!Unlabeled')
			end
		end
	else
		insert(result, self.className)
	end
	
	
	return result
end

function module.destroy(self: object)
	if self.isDestroyed then return end
	
	self.isDestroyed = true
	
	for _, v in next, self.__event_names do
		disguise(self)[`__{v}`]:destroy()
		disguise(self)[`__{v}`] = nil
	end
	
	disguise(self).__super = nil
end

module.from = from
module.className = 'Object'
module.__index = module
module.isClass = Class.isClass
module.hasClass = Class.hasClass
module.__inherit = Class.inherit

module.add =      unimplemented
module.sub =      unimplemented
module.mul =      unimplemented
module.div =      unimplemented
module.mod =      unimplemented
module.pow =      unimplemented
module.idiv =     unimplemented
module.eq =       unimplemented
module.lt =       unimplemented
module.le =       unimplemented
module.concat =   unimplemented
module.len =      unimplemented
module.call =     unimplemented
module.toString = unimplemented

module.__add =    proxyCall'add'
module.__sub =    proxyCall'sub'
module.__mul =    proxyCall'mul'
module.__div =    proxyCall'div'
module.__mod =    proxyCall'mod'
module.__pow =    proxyCall'pow'
module.__idiv =   proxyCall'idiv'
module.__eq =     proxyCall'eq'
module.__lt =     proxyCall'lt'
module.__le =     proxyCall'le'
module.__concat = proxyCall'concat'
module.__len =    proxyCall'len'
module.__call =   proxyCall'call'

return module
