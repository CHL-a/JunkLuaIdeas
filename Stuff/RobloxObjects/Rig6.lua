-- SPEC
local Objects = script.Parent
local Class = require(Objects.Class)
local CharacterRig = require(Objects.CharacterRig)

type __object = {
	leftArm: BasePart;
	rightArm: BasePart;
	leftLeg: BasePart;
	rightLeg: BasePart;
	torso: BasePart;
} & Class.subclass<CharacterRig.object>
export type object = __object

type __constructorArgs = CharacterRig.constructorArgs
export type constructorArgs = __constructorArgs

-- CLASS
local Rig6 = {}
local disguise = require(Objects.LuaUTypes).disguise

Rig6.__index = Rig6

local sides = {'Left', 'Right'}
local limbs = {'Arm', 'Leg'}

function Rig6.new(char:Model, arg: __constructorArgs?): object
	local self: __object = disguise(Class.inherit(CharacterRig.new(char, arg), Rig6))
	
	for _, a in next, sides do
		for _, b in next, limbs do
			self:__setLimbFromConstruction(a..b)
		end
	end
	
	self:__setLimbFromConstruction'Torso'
	
	return self
end

return Rig6
