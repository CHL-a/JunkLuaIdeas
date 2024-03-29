-- TYPES
local Objects = script.Parent
local module = {}

export type object = {-- typeof(setmetatable({}, module))
	className: string;
	
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
}
type method<self, P..., R...> = (self: self, P...) -> (R...)
type binaryMethod = method<(any), (any)>
type relationalMethod = method<(any), (boolean)>

-- MAIN
local Class = require(Objects.Class)
local LuaUTypes = require(Objects.LuaUTypes)
local EventPackage = require(Objects.EventPackage)
local TableUtils = require(Objects["@CHL/TableUtils"])

disguise = LuaUTypes.disguise
unimplemented = disguise(Class.unimplemented)
insert = table.insert
from = {}

function proxyCall(s: string)
	return function(self: object, ...)
		return self[s](self, ...)
	end
end

function module.new(): object return from.rawStruct{}end

function from.rawStruct(t): object
	local self: object = disguise(setmetatable(t, module))
	disguise(self).__supers = {}
	return self
end

function module.__constructEvent(self: object, ...: string): ()
	local __s = disguise(self)
	for i = 1, select('#', ...) do
		local s = select(i, ...)
		__s[`__{s}`] = EventPackage.new()
		__s[s] = __s[`__{s}`].event
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
