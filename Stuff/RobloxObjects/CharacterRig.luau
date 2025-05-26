-- SPEC
local RigBase = require('./@CHL>RigBase')
local Class = require('./Class');

type __object = {
	humanoidRootPart: Part;
	head: BasePart
} & Class.subclass<RigBase.object>
export type object = __object

type __constructorArgs = RigBase.constructorArgs
export type constructorArgs = __constructorArgs

-- CLASS
local CharacterRig = {}

disguise = require('./LuaUTypes').disguise

function CharacterRig.new(char:Model, arg: __constructorArgs?): object
	local self: __object = RigBase.new(char, arg):__inherit(CharacterRig)
		--disguise(Class.inherit(RigBase.new(char, arg), CharacterRig))
	
	self:__setLimbFromConstruction('Head')
	self:__setLimbFromConstruction('HumanoidRootPart')
	
	return self
end

Class.makeProperClass(CharacterRig, '@CHL>CharacterRig')

return CharacterRig
