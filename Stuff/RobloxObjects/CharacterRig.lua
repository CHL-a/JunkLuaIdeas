-- SPEC
local Objects = script.Parent

local RigBase = require(Objects.RigBase)
local Class = require(Objects.Class);

type __object = {
	humanoidRootPart: Part;
	head: BasePart
} & Class.subclass<RigBase.object>
export type object = __object

type __constructorArgs = RigBase.constructorArgs
export type constructorArgs = __constructorArgs

-- CLASS
local CharacterRig = {}

disguise = require(Objects.LuaUTypes).disguise

CharacterRig.new = function(char:Model, arg: __constructorArgs?): object
	local self: __object = RigBase.new(char, arg):__inherit(CharacterRig)
		--disguise(Class.inherit(RigBase.new(char, arg), CharacterRig))
	
	self:__setLimbFromConstruction('Head')
	self:__setLimbFromConstruction('HumanoidRootPart')
	
	return self
end

CharacterRig.__index = CharacterRig
CharacterRig.className = 'CharacterRig'

return CharacterRig
