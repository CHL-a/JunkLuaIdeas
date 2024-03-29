--// TYPE
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object = {
	character: Model;
	humanoid: Humanoid;
	__constructorArg: constructorArgs?;

	findDescendant: <A>(self: object, ...string) -> A?;
	waitDescendant: <A>(self: object, ...string) -> A;
	__getDescendantFromArg: <A>(self: object, ...string) -> A;
	__setLimbFromConstruction: <A>(self: object, ... string) -> A;
} & Class.subclass<Object.object>

export type constructorArgs = {
	shouldYield: boolean?;
}

type __anyFn = (...any) -> ...any

-- CLASS
local Rig = {}
Rig.__index = Rig

disguise = require(Objects.LuaUTypes).disguise()

function Rig.new(char: Model, arg: constructorArgs?): object
	local self: object = Object.new():__inherit(Rig)
	self.character = char
	self.__constructorArg = arg or {}
	
	-- mind this
	self:__setLimbFromConstruction('Humanoid')
	
	return self
end

Rig.findDescendant = function(self:object, ...: string)
	local result = self.character
	
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		result = result:FindFirstChild(n)
		if not result then return end
	end
	
	return result
end

Rig.waitDescendant = function(self:object, ...: string)
	local result = self.character
	
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		result = result:WaitForChild(n)
		if not result then return end;
	end
	
	return result
end

Rig.__getDescendantFromArg = function(self:object, ...: string)
	local arg = self.__constructorArg
	
	return assert(
		self:findDescendant(...) or 
			arg and arg.shouldYield and 
			self:waitDescendant(...),
		`Missing descendant: {table.concat({...}, '.')}`
	)
end

Rig.__setLimbFromConstruction = function(self:object, ...: string)
	local n = select(select('#', ...),...)
	local obj = self:__getDescendantFromArg(...)
	disguise(self)[n:sub(1,1):lower() .. n:sub(2)] = obj

	return obj
end


return Rig
