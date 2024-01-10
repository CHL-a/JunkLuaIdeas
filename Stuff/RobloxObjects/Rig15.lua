-- SPEC
local Objects = script.Parent
local CharacterRig = require(Objects.CharacterRig)
local Class = require(Objects.Class)
local IKCollection = require(Objects['@CHL/IKCollection'])

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
	
	-- ik
	leftSole: Attachment;
	rightSole: Attachment;
	ikCollection: IKCollection.object;
	rightFootTarget: Attachment;
	leftFootTarget: Attachment;
	leftHandTarget: Attachment;
	rightHandTarget: Attachment;
	
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
local Dash = require(Objects["@CHL/DashSingular"])
local InstanceUtils = require(Objects["@CHL/InstanceUtils"]) 

local create = InstanceUtils.create

Rig15.__index = Rig15

local sides = {'Left', 'Right'}
local limbs = {'Arm', 'Leg'}
local sections = {'Upper','Lower'}
local isClient = game:GetService('RunService'):IsClient()

function Rig15.new(char:Model, arg: __constructorArgs?): object
	local self: __object = disguise(Class.inherit(CharacterRig.new(char, arg), Rig15))

	-- torso
	self.limbs = TableUtils.push({}, 
		self:__setLimbFromConstruction'UpperTorso',
		self:__setLimbFromConstruction'LowerTorso',
		self.head
	)
	
	self.motor6Ds = TableUtils.push({},
		self:__setLimbFromConstruction('Head', 'Neck'),
		self:__setLimbFromConstruction('UpperTorso','Waist'),
		self:__setLimbFromConstruction('LowerTorso', 'Root')
	)

	--ik control
	self.ikCollection = IKCollection.new()
	
	-- other states
	local __self = disguise(self)
	local hrp = self.humanoidRootPart
	
	for _, a in next, sides do -- per side
		for _, b in next, sections do -- sections
			for _, c in next, limbs do -- limbs
				table.insert(self.limbs, self:__setLimbFromConstruction(a .. b .. c))
			end
		end
		
		-- limbs
		local highFootName = `{a}Foot`
		
		TableUtils.push(self.limbs,
			self:__setLimbFromConstruction(highFootName),
			self:__setLimbFromConstruction(`{a}Hand`)
		)
		
		-- m6ds
		TableUtils.push(self.motor6Ds,
			self:__setLimbFromConstruction(`{a}Foot`,`{a}Ankle`),
			self:__setLimbFromConstruction(`{a}LowerLeg`,`{a}Knee`),
			self:__setLimbFromConstruction(`{a}UpperLeg`,`{a}Hip`),
			self:__setLimbFromConstruction(`{a}Hand`,`{a}Wrist`),
			self:__setLimbFromConstruction(`{a}LowerArm`,`{a}Elbow`),
			self:__setLimbFromConstruction(`{a}UpperArm`,`{a}Shoulder`)
		)
		
		-- sole + inv kin + foot target + hand target
		local b = a:sub(1,1):lower() .. a:sub(2)
		local footName = `{b}Foot`
		local foot = __self[footName]
		local soleName = `{b}Sole`
		local handName = `{b}Hand`
		local hand = __self[handName]
		local lowerLeg = __self[`{b}LowerLeg`]
		local lowerArm = __self[`{b}LowerArm`]
		
		local sole: Attachment,
			footIKC,
			handIKC,
			footTarget,
			handTarget = disguise()
		
		if isClient then
			sole = self:__getDescendantFromArg(highFootName, soleName)
			footIKC = self:__getDescendantFromArg('Humanoid', footName)
			handIKC = self:__getDescendantFromArg('Humanoid', handName)
			footTarget = self:__getDescendantFromArg('HumanoidRootPart', `__{b}FootTarget`)
			handTarget = self:__getDescendantFromArg('HumanoidRootPart', `__{b}HandTarget`)
		else
			sole = Instance.new('Attachment', foot)
			sole.Position = Vector3.new(0,-foot.Size.Y / 2)
			sole.Name = soleName
			
			footIKC = Instance.new('IKControl') 
			footIKC.Enabled = false;
			footIKC.ChainRoot = __self[`{b}UpperLeg`];
			footIKC.EndEffector = sole;
			footIKC.Name = footName
			footIKC.Parent = self.humanoid
			
			handIKC = footIKC:Clone()
			handIKC.ChainRoot = __self[`{b}UpperArm`];
			handIKC.EndEffector = hand;
			handIKC.Name = handName;
			handIKC.Parent = self.humanoid
			
			footTarget = Instance.new('Attachment')
			footTarget.Position = Vector3.new(
				(a == 'Right' and 1 or -1)  * .8,
				-hrp.Size.Y/2 - self.humanoid.HipHeight
			)
			footTarget.Name = `__{b}FootTarget`
			footTarget.Parent = hrp
			footIKC.Target = footTarget;
			
			local kneeHinge = Instance.new('HingeConstraint')
			kneeHinge.Name = '__knee'
			kneeHinge.Attachment0 = __self[`{b}UpperLeg`][`{a}KneeRigAttachment`]
			kneeHinge.Attachment1 = lowerLeg[`{a}KneeRigAttachment`]
			kneeHinge.LimitsEnabled = true
			kneeHinge.LowerAngle = -135
			-- upper angle subjected to limitations
			kneeHinge.Parent = footIKC

			local ankleAt1: Attachment = foot[`{a}AnkleRigAttachment`]:Clone()
			ankleAt1.Orientation = Vector3.new(0,0,90)
			ankleAt1.Name = 'AnkleAttachment1'
			ankleAt1.Parent = foot;

			local ankleAt0: Attachment = lowerLeg[`{a}AnkleRigAttachment`]:Clone()
			ankleAt0.WorldOrientation = ankleAt1.WorldOrientation
			ankleAt0.Name = 'AnkleAttachment0'
			ankleAt0.Parent = lowerLeg;

			local ankleBS = Instance.new('BallSocketConstraint')
			ankleBS.Name = '__ankle'
			ankleBS.Attachment1 = ankleAt1
			ankleBS.Attachment0 = ankleAt0
			ankleBS.LimitsEnabled = true
			ankleBS.UpperAngle = 70
			ankleBS.TwistLimitsEnabled = true
			ankleBS.TwistLowerAngle = -45
			ankleBS.TwistUpperAngle = 45
			ankleBS.Parent = footIKC
			
			handTarget = Instance.new('Attachment')
			handTarget.Position = Vector3.new(
				(a == 'Right' and 1 or -1) * 1,
				0,
				-1
			)
			handTarget.Orientation = Vector3.new(90)
			handTarget.Name = `__{b}HandTarget`
			handTarget.Parent = hrp
			handIKC.Target = handTarget;
			
			local elbowHinge = Instance.new('HingeConstraint')
			elbowHinge.Name = '__elbow'
			elbowHinge.Attachment0 = __self[`{b}UpperArm`][`{a}ElbowRigAttachment`]
			elbowHinge.Attachment1 = lowerArm[`{a}ElbowRigAttachment`]
			elbowHinge.LimitsEnabled = true
			elbowHinge.UpperAngle = 135
			-- upper angle subjected to limitations
			elbowHinge.Parent = handIKC

			local wristAt1: Attachment = hand[`{a}WristRigAttachment`]:Clone()
			wristAt1.Orientation = Vector3.new(0,0,90)
			wristAt1.Name = 'WristAttachment1'
			wristAt1.Parent = hand;

			local wristAt0: Attachment = lowerArm[`{a}WristRigAttachment`]:Clone()
			wristAt0.WorldOrientation = wristAt1.WorldOrientation
			wristAt0.Name = 'WristAttachment0'
			wristAt0.Parent = lowerArm;

			local wristBS = Instance.new('BallSocketConstraint')
			wristBS.Name = '__wrist'
			wristBS.Attachment1 = wristAt1
			wristBS.Attachment0 = wristAt0
			wristBS.LimitsEnabled = true
			wristBS.UpperAngle = 100
			wristBS.Parent = handIKC
		end
		
		__self[soleName] = sole
		self.ikCollection:add(footIKC, handIKC)
		__self[`{footName}Target`] = footTarget
		__self[`{handName}Target`] = handTarget
	end
	
	self.ikCollection:enable(false)
	
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
	disguise(TableUtils).clearNils
)

Rig15.getLimbs = Dash.compose(
	function(self: __object)return self.limbs end,
	table.clone,
	disguise(TableUtils).clearNils
)



return Rig15
