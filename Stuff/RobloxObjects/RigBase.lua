--// TYPE
type __object = {
	character: Model;
	humanoid: Humanoid;
	__constructorArg: __constructorArgs?;
	
	findDescendant: <A>(self:__object, ...string) -> A?;
	waitDescendant: <A>(self:__object, ...string) -> A;
	__getDescendantFromArg: <A>(self:__object, ...string) -> A;
	__setLimbFromConstruction: <A>(self:__object, ... string) -> A;
}
export type object = __object

type __constructorArgs = {
	shouldYield: boolean?;
}
export type constructorArgs = __constructorArgs

type __anyFn = (...any) -> ...any

-- CLASS
local Rig = {}
Rig.__index = Rig

function disguise<A...>(...: any): A...return...end
--local disguise = require(sc)

function Rig.new(char: Model, arg: __constructorArgs?): __object
	local self: __object = disguise(setmetatable({}, Rig))
	self.character = char
	self.__constructorArg = arg or {}
	
	-- mind this
	self:__setLimbFromConstruction('Humanoid')
	
	return self
end

Rig.findDescendant = function(self:__object, ...: string)
	local result = self.character
	
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		result = result:FindFirstChild(n)
		if not result then return end
	end
	
	return result
end

Rig.waitDescendant = function(self:__object, ...: string)
	local result = self.character
	
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		result = result:WaitForChild(n)
		if not result then return end;
	end
	
	return result
end

Rig.__getDescendantFromArg = function(self:__object, ...: string)
	local arg = self.__constructorArg
	
	return assert(
		self:findDescendant(...) or 
			arg and arg.shouldYield and 
			self:waitDescendant(...),
		`Missing descendant: {table.concat({...}, '.')}`
	)
end

Rig.__setLimbFromConstruction = function(self:__object, ...: string)
	local n = select(select('#', ...),...)
	local obj = self:__getDescendantFromArg(...)
	disguise(self)[n:sub(1,1):lower() .. n:sub(2)] = obj

	return obj
end


return Rig
