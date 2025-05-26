--// TYPE
local Object = require('./Object')
local Class = require('./Class')

export type object = {
	character: Model;
	humanoid: Humanoid;
	__constructorArg: constructorArgs?;

	findDescendant: <A>(self: object, ...string) -> A?;
	waitDescendant: <A>(self: object, ...string) -> A;
	__getDescendantFromArg: <A>(self: object, ...string) -> A;
	__setLimbFromConstruction: <A>(self: object, ... string) -> A;
} & Object.object_inheritance

export type constructorArgs = {
	shouldYield: boolean?;
}

type __anyFn = (...any) -> ...any

-- CLASS
local Rig = {}

disguise = require('./LuaUTypes').disguise

function Rig.new(char: Model, arg: constructorArgs?): object
	local self: object = Object.new():__inherit(Rig)
	self.character = char
	self.__constructorArg = arg or {}
	
	-- mind this
	self:__setLimbFromConstruction('Humanoid')
	
	return self
end

function Rig.findDescendant(self:object, ...: string)
	local result = self.character
	
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		result = result:FindFirstChild(n)
		if not result then return end
	end
	
	return result
end

function Rig.waitDescendant(self:object, ...: string)
	local result = self.character
	
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		result = result:WaitForChild(n)
		if not result then return end;
	end
	
	return result
end

function Rig.__getDescendantFromArg(self:object, ...: string)
	local arg = self.__constructorArg
	
	return assert(
		self:findDescendant(...) or 
			arg and arg.shouldYield and 
			self:waitDescendant(...),
		`Missing descendant: {table.concat({...}, '.')}`
	)
end

function Rig.__setLimbFromConstruction(self:object, ...: string)
	local n = select(select('#', ...),...)
	local obj = self:__getDescendantFromArg(...)
	disguise(self)[n:sub(1,1):lower() .. n:sub(2)] = obj

	return obj
end

Class.makeProperClass(Rig, '@CHL>RigBase')

return Rig
