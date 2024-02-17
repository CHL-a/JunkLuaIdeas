--[[See stream in computer programming]]
--// TYPES
local Objects = script.Parent
export type object<A> = {
	getF: <B>(...B) -> ...A;
	appendF: <B>(...B) -> ();
	
	get: <B>(self: object<A>, ...B) -> A;
	append: <B>(self: object<A>, ...B) -> ();
}

--// MAIN
local Stream = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise
Stream.__index = Stream

function Stream.new<A, B>(
	getFunc: <B>(...B) -> ...A, 
	appendFunc: <B>(...B) -> ())
	
	-- pre
	assert(
		(
			getFunc == nil or 
			type(getFunc) == 'function'
		) and (
			appendFunc == nil or
			type(appendFunc) == 'function'
		)
	)
	
	-- main
	local self: object<A> = disguise(setmetatable({}, Stream))
	
	self.getF = getFunc
	self.appendF = appendFunc
	
	return self
end

Stream.get = function<A, B>(self: object<A>, ...: B): ...A return self.getF(...)end
Stream.append = function<A, B>(self: object<A>, ...: B)self.appendF(...)end

return Stream
