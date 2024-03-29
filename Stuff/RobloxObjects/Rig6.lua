-- SPEC
local Objects = script.Parent

local Class = require(Objects.Class)
local CharacterRig = require(Objects.CharacterRig)

export type object = {
	leftArm: BasePart;
	rightArm: BasePart;
	leftLeg: BasePart;
	rightLeg: BasePart;
	torso: BasePart;
} & Class.subclass<CharacterRig.object>

export type constructorArgs = CharacterRig.constructorArgs

-- CLASS
local Rig6 = {}

disguise = require(Objects.LuaUTypes).disguise

local sides = {'Left', 'Right'}
local limbs = {'Arm', 'Leg'}

function Rig6.new(char:Model, arg: constructorArgs?): object
	local self: object = CharacterRig.new(char, arg):__inherit(Rig6)
		-- disguise(Class.inherit(CharacterRig.new(char, arg), Rig6))
	
	for _, a in next, sides do
		for _, b in next, limbs do
			self:__setLimbFromConstruction(a..b)
		end
	end
	
	self:__setLimbFromConstruction'Torso'
	
	return self
end

Rig6.__index = Rig6
Rig6.className = 'Rig6'


return Rig6
