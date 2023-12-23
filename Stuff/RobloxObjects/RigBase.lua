--// TYPE
type __object = {
	character: Model;
	humanoid: Humanoid;
	__constructorArg: __constructorArgs?;
	
	findChild: <A>(self:__object, name: string) -> A?;
	waitChild: <A>(self:__object, name: string) -> A;
	__getChildFromArg: <A>(self:__object, name: string) -> A;
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
	self.humanoid = self:__getChildFromArg('Humanoid')
	
	return self
end

Rig.findChild = function(self:__object, n: string)return self.character:FindFirstChild(n)end
Rig.waitChild = function(self:__object, n: string)return self.character:WaitForChild(n)end

Rig.__getChildFromArg = function(self:__object, n: string)
	local arg = self.__constructorArg
	
	return assert(
		self:findChild(n) or arg and arg.shouldYield and self:waitChild(n),
		`Missing child: {n}`
	)
end


return Rig
