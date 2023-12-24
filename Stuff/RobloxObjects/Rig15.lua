-- SPEC
local Objects = script.Parent
local CharacterRig = require(Objects.CharacterRig)
local Class = require(Objects.Class)

type __object = {
	-- States

	-- right leg
	rightUpperLeg: BasePart;
	rightLowerLeg: BasePart;
	rightFoot: BasePart;

	rightAnkle: Motor6D;
	rightKnee: Motor6D;
	rightHip: Motor6D;

	-- left leg
	leftUpperLeg: BasePart;
	leftLowerLeg: BasePart;
	leftFoot: BasePart;

	leftAnkle: Motor6D;
	leftKnee: Motor6D;
	leftHip: Motor6D;

	-- torso
	upperTorso: BasePart;
	lowerTorso: BasePart;

	waist: Motor6D;
	root: Motor6D;
	neck: Motor6D;

	-- right arm
	rightUpperArm: BasePart;
	rightLowerArm: BasePart;
	rightHand: BasePart;

	rightWrist: Motor6D;
	rightElbow: Motor6D;
	rightShoulder: Motor6D;

	-- left arm
	leftUpperArm: BasePart;
	leftLowerArm: BasePart;
	leftHand: BasePart;

	leftWrist: Motor6D;
	leftElbow: Motor6D;
	leftShoulder: Motor6D;
	
	motor6Ds: {Motor6D};
	limbs: {BasePart};
	
	-- Methods
	getMotor6Ds: (self:__object) -> {Motor6D};
	getLimbs: (self:__object) -> {BasePart};
	__setLimbFromConstruction: <A>(self:__object, ... string) -> A;
	
} & Class.subclass<CharacterRig.object>
export type object = __object

type __constructorArgs = CharacterRig.constructorArgs
export type constructorArgs = __constructorArgs

-- CLASS
local Rig15 = {}
local disguise = require(Objects.LuaUTypes).disguise
local TableUtils = require(Objects["@CHL/TableUtils"])
local DashInterface = require(Objects.DashInterface)
local Dash = require(Objects.Dash) :: DashInterface.module

Rig15.__index = Rig15

local sides = {'Left', 'Right'}
local limbs = {'Arm', 'Leg'}
local sections = {'Upper','Lower'}

function Rig15.new(char:Model, arg: __constructorArgs?): object
	local self: __object = disguise(Class.inherit(CharacterRig.new(char, arg), Rig15))

	self.motor6Ds = {}
	-- torso
	
	self.limbs = TableUtils.push({}, 
		self:__setLimbFromConstruction'UpperTorso',
		self:__setLimbFromConstruction'LowerTorso'
	)
	
	self.motor6Ds = TableUtils.push({},
		self:__setLimbFromConstruction('Head', 'Neck'),
		self:__setLimbFromConstruction('UpperTorso','Waist'),
		self:__setLimbFromConstruction('LowerTorso', 'Root')
	)
	
	-- others
	local __self = disguise(self)
	
	for _, a in next, sides do -- per side
		for _, b in next, sections do -- sections
			for _, c in next, limbs do -- limbs
				table.insert(self.limbs, self:__setLimbFromConstruction(a .. b .. c))
			end
		end
		
		-- legs
		table.insert(self.limbs, self:__setLimbFromConstruction(`{a}Foot`))
		TableUtils.push(self.motor6Ds,
			self:__setLimbFromConstruction(`{a}Foot`,`{a}Ankle`),
			self:__setLimbFromConstruction(`{a}LowerLeg`,`{a}Knee`),
			self:__setLimbFromConstruction(`{a}UpperLeg`,`{a}Hip`)
		)
		
		-- arms
		table.insert(self.limbs, self:__setLimbFromConstruction(`{a}Hand`))
		TableUtils.push(self.motor6Ds,
			self:__setLimbFromConstruction(`{a}Hand`,`{a}Wrist`),
			self:__setLimbFromConstruction(`{a}LowerArm`,`{a}Elbow`),
			self:__setLimbFromConstruction(`{a}UpperArm`,`{a}Shoulder`)
		)
	end
	
	return self
end

Rig15.__setLimbFromConstruction = function(self:__object, ...: string)
	local n = select(select('#', ...),...)
	local obj = self:__getDescendantFromArg(...)
	disguise(self)[n:sub(1,1):lower() .. n:sub(2)] = obj
	
	return obj
end

Rig15.getMotor6Ds = Dash.compose(
	function(self: __object)return self.motor6Ds end,
	table.clone,
	TableUtils.clearNils
)

Rig15.getLimbs = Dash.compose(
	function(self: __object)return self.limbs end,
	table.clone,
	TableUtils.clearNils
)



return Rig15
