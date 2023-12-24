-- SPEC
local Objects = script.Parent
local RigBase = require(Objects.RigBase)
local Class = require(Objects.Class)

type __object = {
	humanoidRootPart: Part;
	head: BasePart
} & Class.subclass<RigBase.object>
export type object = __object

type __constructorArgs = RigBase.constructorArgs
export type constructorArgs = __constructorArgs

-- CLASS
local CharacterRig = {}
local disguise = require(Objects.LuaUTypes).disguise

CharacterRig.__index = CharacterRig

CharacterRig.new = function(char:Model, arg: __constructorArgs?): object
	local self: __object = disguise(Class.inherit(RigBase.new(char, arg), CharacterRig))
	
	self:__setLimbFromConstruction('Head')
	self:__setLimbFromConstruction('HumanoidRootPart')
	
	return self
end

return CharacterRig
