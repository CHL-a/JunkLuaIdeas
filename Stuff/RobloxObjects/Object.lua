-- TYPES
local Objects = script.Parent
local module = {}

export type object = typeof(setmetatable({}, module))
type method<P..., R...> = (self: object, P...) -> (R...)
type binaryMethod = method<(any), (any)>
type relationalMethod = method<(any), (boolean)>

-- MAIN
local Class = require(Objects.Class)
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise
unimplemented = disguise(Class.unimplemented) 

function module.new(): object return setmetatable({}, module)end

function proxyCall(s: string)
	return function(self: object, ...)
		return self[s](self, ...)
	end
end

module.__index = module
module.isClass = Class.isClass :: (self: object, C: any) -> boolean
module.hasClass = Class.hasClass :: (self: object, C: any) -> boolean

module.add =    unimplemented :: binaryMethod
module.sub =    unimplemented :: binaryMethod
module.mul =    unimplemented :: binaryMethod
module.div =    unimplemented :: binaryMethod
module.mod =    unimplemented :: binaryMethod
module.pow =    unimplemented :: binaryMethod
module.idiv =   unimplemented :: binaryMethod
module.eq =     unimplemented :: relationalMethod
module.lt =     unimplemented :: relationalMethod
module.le =     unimplemented :: relationalMethod
module.concat = unimplemented :: binaryMethod
module.len =    unimplemented :: method<(), (any)>
module.call =   unimplemented :: method<(...any), (...any)>

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
