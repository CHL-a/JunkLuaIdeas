-- SPEC
local Objects = script.Parent
local CharacterRig = require(Objects.CharacterRig)
local Class = require(Objects.Class)
local IKCollection = require(Objects['@CHL/IKCollection'])
local ProceduralLeg = require(Objects["@CHL/ProceduralLeg"])
local RuntimeUpdater = require(Objects.RuntimeUpdater)
local Spring = require(Objects["@CHL/Spring"])

type __walkState = 'idle' | 'forward' | 'backward' | 'left' | 'right'

type __walker = {
	leftLeg: ProceduralLeg.object;
	rightLeg: ProceduralLeg.object;
	isUsingLeft: boolean;
	rightStep: Vector3;
	leftStep: Vector3;
	rig: __object;
	walkingState: __walkState;
	enabled: boolean;
	enable: (self: __walker, boolean) -> nil;
} & RuntimeUpdater.updatable

type __side = 'Left' | 'Right'

type __object = {
	-- States
	__constructorArg: __constructorArgs;

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
	walker: __walker;
	
	-- Methods
	getMotor6Ds: (self:__object) -> {Motor6D};
	getLimbs: (self:__object) -> {BasePart};
	__setLimbFromConstruction: <A>(self:__object, ... string) -> A;
	isAtFront: (self:__object, world: Vector3) -> boolean;
	getRelativeVelocity: (self: __object) -> Vector3;
	getAngleRelativeToFloor: (self: __object, epsilon: number) -> (number, boolean);
	getFrontReference: (self:__object) -> Vector3;
	getBackReference: (self:__object) -> Vector3;
	getLeftReference: (self:__object) -> Vector3;
	getRightReference: (self: __object) -> Vector3;
	isAtRight: (self:__object, world: Vector3) -> Vector3;
} & Class.subclass<CharacterRig.object>
export type object = __object

type __constructorArgs = {
	loadWalker: boolean?;
} & CharacterRig.constructorArgs
export type constructorArgs = __constructorArgs

-- CLASS
local Rig15 = {}
local LuaUTypes = require(Objects.LuaUTypes)
local TableUtils = require(Objects["@CHL/TableUtils"])
local Dash = require(Objects["@CHL/DashSingular"])
local InstanceUtils = require(Objects["@CHL/InstanceUtils"])
local Vector3Utils = require(Objects.Vector3Utils)

disguise = LuaUTypes.disguise
compose = Dash.compose
imprint = TableUtils.imprint
create = InstanceUtils.create

sides = {'Left', 'Right'}
limbs = {'Arm', 'Leg'}
sections = {'Upper','Lower'}
isClient = game:GetService('RunService'):IsClient()
pi = math.pi
vFloor = Vector3.new(1,0,1)

--[[
###########################################################################################
###########################################################################################
###########################################################################################
--]]

local Walker = {}

Walker.__index = Walker
Walker.hoverPositions = {
	idle     = {left = Vector3.new(-.5)     ;right = Vector3.new(.5)     };
	forward  = {left = Vector3.new(-.5,0,-1);right = Vector3.new(.5,0,-1)};
	backward = {left = Vector3.new(-.5,0,1) ;right = Vector3.new(.5,0,1)};
	right    = {left = Vector3.new(1,0,-.75);right = Vector3.new(1.25)};
	left     = {left = Vector3.new(-1.25)   ;right = Vector3.new(-1,0,-.75)}
}

function Walker.new(rig: __object): __walker
	local self: __walker = disguise(setmetatable({}, Walker))
	local __self, __rig = disguise(self, rig)
	
	self.canUpdate = true
	self.rig = rig
	self.walkingState = 'idle'
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {rig.character}
	
	local hrp = rig.humanoidRootPart
	local halfYSize = hrp.Size.Y / 2
	
	for _, a in next, sides do
		local b = a:sub(1,1):lower() .. a:sub(2)
		local upperLeg = __rig[`{b}UpperLeg`]
		local foot = __rig[`{b}Foot`]
		local right1 = a == 'Right' and 1 or -1
		
		local foundTargetHover = hrp:FindFirstChild(`__{b}TargetHover`)
		local arg = {
			legJoints = {
				upperLeg[`{a}HipRigAttachment`],
				upperLeg[`{a}KneeRigAttachment`],
				foot[`{a}AnkleRigAttachment`],
				__rig[`{b}Sole`]
			};
			footTarget = __rig[`{b}FootTarget`];
			rayParams = params;
			targetHover = foundTargetHover;
			iKControl = rig.ikCollection:getIKControlFromEnd(__rig[`{b}Sole`])
		} :: ProceduralLeg.constructorArgs
		local pLeg = ProceduralLeg.new(arg)
		
		
		if not foundTargetHover then
			local targetHover = pLeg.targetHover
			targetHover.Position = Vector3.new(.5 * right1, -halfYSize, -1)
			targetHover.Name = `__{b}TargetHover`
			targetHover.Parent = hrp
		end
		
		__self[`{b}Leg`] = pLeg
		disguise(rig.ikCollection:getIKControlFromEnd(__rig[`{b}Sole`])).SmoothTime = 0
	end
	
	return self
end

function convertHoverPosition(s: string, y: number)
	local set = Walker.hoverPositions[s]
	return set.left + Vector3.new(0, y), set.right + Vector3.new(0, y)
end

Walker.enable = function(self:__walker, b: boolean)
	local rig = self.rig :: __object
	
	self.enabled = b;
	
	rig.ikCollection:getIKControlFromEnd(self.rightLeg.foot).Enabled = b;
	rig.ikCollection:getIKControlFromEnd(self.leftLeg.foot).Enabled = b;
end

Walker.update = function(self: __walker, dt: number)
	local rightLeg = self.rightLeg
	local leftLeg = self.leftLeg
	local rig = self.rig::__object
	local angle, isWalking = rig:getAngleRelativeToFloor(1)
	
	angle *= 180 / pi
	
	local cf = rig.humanoidRootPart.CFrame

	local leftPosSpring = leftLeg.positionSpring
	local rightPosSpring = rightLeg.positionSpring
	local leftSpringP = leftPosSpring.p
	local rightSpringP = rightPosSpring.p
	local leftT = leftPosSpring.t
	local rightT = rightPosSpring.t
	
	-- state change
	local walkingState: __walkState = nil
	if not isWalking then walkingState = 'idle'
	elseif angle > -60 and angle < 60 then walkingState = 'forward'
	elseif angle >= 60 and angle < 120 then walkingState = 'left'
	elseif angle > -120 and angle <= -60 then walkingState = "right"
	else walkingState = 'backward'
	end
	
	--print(walkingState)
	
	self.walkingState = walkingState
	
	-- reflect state change
	local y = rightLeg.targetHover.Position.Y
	
	if workspace.updateHover.Value then
		leftLeg.targetHover.Position, rightLeg.targetHover.Position = 
			convertHoverPosition(walkingState, y)
	end
	
	-- update springs
	rightLeg:update(dt)
	leftLeg:update(dt)
	
	-- check step sides
	if 
		workspace.updateHover.Value and
		
		leftSpringP:FuzzyEq(leftT, .01) and rightSpringP:FuzzyEq(rightT, .01) then
		local referral: Vector3 = nil
		
		-- get reference for compare
		if walkingState == 'left' or walkingState == 'right' then
			local leftLegX = rig:isAtRight(leftT)
			local isOnSameX = leftLegX == rig:isAtRight(rightT)
			
			if isOnSameX and leftLegX == (walkingState == 'right') then
				if leftLegX then
					referral = rig:getRightReference()
				else
					referral = rig:getLeftReference()
				end
			end
		else
			local leftLegZ = rig:isAtFront(leftT)
			local isOnSameZ = leftLegZ == rig:isAtFront(rightT)
			
			if isOnSameZ and (not leftLegZ) == (walkingState ~= 'backward') then
				if not leftLegZ then
					referral = rig:getBackReference()
				else
					referral = rig:getFrontReference()
				end
			end
		end
		
		-- update the step that is the closest
		if referral then
			if Vector3Utils.getCloserVector3(
				referral, leftT, rightT) == leftT then
				leftLeg:updateStep()
			else
				leftLeg:updateStep()
			end
		end
	end
end

--[[
###########################################################################################
###########################################################################################
###########################################################################################
--]]

Rig15.__index = Rig15

function Rig15.new(char:Model, arg: __constructorArgs?): object
	local self: __object = disguise(Class.inherit(CharacterRig.new(char, arg), Rig15))
	local __arg = self.__constructorArg :: __constructorArgs

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
		local upperLeg = __self[`{b}UpperLeg`]
		
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
			-- feet
			sole = imprint(Instance.new('Attachment'), {
				Name = soleName;
				Position = Vector3.new(0,-foot.Size.Y / 2)
			})
			sole.Parent = foot
			
			footIKC = imprint(Instance.new('IKControl'), {
				Enabled = false;
				ChainRoot = upperLeg;
				EndEffector = sole;
				Name = footName
			})
			footIKC.Parent = self.humanoid
			
			footTarget = imprint(Instance.new('Attachment'),{
				Position = Vector3.new(
					(a == 'Right' and 1 or -1)  * .8,
					-hrp.Size.Y/2 - self.humanoid.HipHeight
				);
				Name = `__{b}FootTarget`
			})
			footTarget.Parent = hrp
			footIKC.Target = footTarget;
			
			local kneeHinge = imprint(Instance.new('HingeConstraint'),{
				Name = '__knee';
				Attachment0 = upperLeg[`{a}KneeRigAttachment`];
				Attachment1 = lowerLeg[`{a}KneeRigAttachment`];
				LimitsEnabled = true;
			})
			kneeHinge.LowerAngle = -135
			kneeHinge.UpperAngle = 0
			-- upper angle subjected to limitations
			kneeHinge.Parent = footIKC

			local ankleAt1: Attachment = imprint(foot[`{a}AnkleRigAttachment`]:Clone(),{
				Orientation = Vector3.new(0,0,90);
				Name = 'AnkleAttachment1'
			})
			ankleAt1.Parent = foot;

			local ankleAt0: Attachment = imprint(lowerLeg[`{a}AnkleRigAttachment`]:Clone(),{
				WorldOrientation = ankleAt1.WorldOrientation;
				Name = 'AnkleAttachment0'
			})
			ankleAt0.Parent = lowerLeg;

			local ankleBS = imprint(Instance.new('BallSocketConstraint'), {
				Name = '__ankle';
				Attachment1 = ankleAt1;
				Attachment0 = ankleAt0;
				LimitsEnabled = true;
			})
			imprint(ankleBS, {UpperAngle = 70;TwistLimitsEnabled = true;})
			imprint(ankleBS, {TwistLowerAngle = -45;TwistUpperAngle = 45})
			ankleBS.Parent = footIKC
			
			local hipAt1: Attachment = imprint(upperLeg[`{a}HipRigAttachment`]:Clone(), {
				Orientation = Vector3.new(0,0,90);
				Name = 'HipAttachment1'
			})
			hipAt1.Parent = upperLeg;

			local hipAt0:Attachment=imprint(__self.lowerTorso[`{a}HipRigAttachment`]:Clone(),{
				WorldOrientation = hipAt1.WorldOrientation;
				Name = 'HipAttachment0'
			})
			hipAt0.Parent = self.lowerTorso;
			
			local hipBS = imprint(Instance.new('BallSocketConstraint'), {
				Name = '__hip';
				LimitsEnabled = true;
				Attachment1 = hipAt1;
				Attachment0 = hipAt0;
			})
			imprint(hipBS, {TwistLimitsEnabled = true;UpperAngle = 90})
			imprint(hipBS, {TwistLowerAngle = -45;TwistUpperAngle = 45})
			hipBS.Parent = footIKC;
			
			-- hands
			handIKC = imprint(footIKC:Clone(),{
				ChainRoot = __self[`{b}UpperArm`];
				EndEffector = hand;
				Name = handName;
			})
			handIKC.Parent = self.humanoid
			
			handTarget = imprint(Instance.new('Attachment'), {
				Position = Vector3.new((a == 'Right' and 1 or -1) * 1, 0, -1);
				Orientation = Vector3.new(90);
				Name = `__{b}HandTarget`
			})
			handTarget.Parent = hrp
			handIKC.Target = handTarget;
			
			local elbowHinge = imprint(Instance.new('HingeConstraint'), {
				Name = '__elbow';
				Attachment0 = __self[`{b}UpperArm`][`{a}ElbowRigAttachment`];
				Attachment1 = lowerArm[`{a}ElbowRigAttachment`];
				LimitsEnabled = true
			})
			elbowHinge.UpperAngle = 135
			-- upper angle subjected to limitations
			elbowHinge.Parent = handIKC

			local wristAt1: Attachment = imprint(hand[`{a}WristRigAttachment`]:Clone(), {
				Orientation = Vector3.new(0,0,90);
				Name = 'WristAttachment1'
			})
			wristAt1.Parent = hand;

			local wristAt0: Attachment = imprint(lowerArm[`{a}WristRigAttachment`]:Clone(),{
				WorldOrientation = wristAt1.WorldOrientation;
				Name = 'WristAttachment0'
			})
			wristAt0.Parent = lowerArm;

			local wristBS = imprint(Instance.new('BallSocketConstraint'), {
				Name = '__wrist';
				Attachment1 = wristAt1;
				Attachment0 = wristAt0;
				LimitsEnabled = true
			})
			wristBS.UpperAngle = 100
			wristBS.Parent = handIKC
		end
		
		__self[soleName] = sole
		self.ikCollection:add(footIKC, handIKC)
		__self[`{footName}Target`] = footTarget
		__self[`{handName}Target`] = handTarget
	end
	
	self.ikCollection:enable(false)
	
	if __arg.loadWalker then
		self.walker = Walker.new(self)
	end
	
	return self
end

Rig15.__setLimbFromConstruction = function(self:__object, ...: string)
	local n = select(select('#', ...),...)
	local obj = self:__getDescendantFromArg(...)
	disguise(self)[n:sub(1,1):lower() .. n:sub(2)] = obj
	
	return obj
end

getNillessArray = compose(table.clone,TableUtils.clearNils)
getHumanoidRootPart = function(self:__object)return self.humanoidRootPart;end
getPositionAndVelocity = function(p: Part)return p.CFrame, p.AssemblyLinearVelocity;end
getHrpPNV = compose(getHumanoidRootPart,getPositionAndVelocity)
plusVector=function(s,m)return function(cf:CFrame)return cf.Position+disguise(cf)[s]*m;end;end

Rig15.getMotor6Ds = function(self: __object)return getNillessArray(self.motor6Ds)end
Rig15.getLimbs=function(self:__object)return getNillessArray(disguise(self).limbs)end
Rig15.getRelativeVelocity = compose(getHrpPNV,Vector3Utils.getRelativeVector)
Rig15.getFrontReference = compose(getHrpPNV,plusVector('LookVector',1))
Rig15.getBackReference = compose(getHrpPNV,plusVector('LookVector',-1))
Rig15.getRightReference = compose(getHrpPNV,plusVector('RightVector',1))
Rig15.getLeftReference = compose(getHrpPNV,plusVector('RightVector',-1))

Rig15.getAngleRelativeToFloor = function(self: __object, epsilon: number)
	local h = self.humanoidRootPart
	local v = h.AssemblyLinearVelocity * vFloor
	local c = h.CFrame
	
	return (c.LookVector * vFloor):Angle(v, Vector3.yAxis),
		v.Magnitude > epsilon
end

Rig15.isAtFront = function(self: __object, world: Vector3):boolean
	local front = self:getFrontReference()

	return Vector3Utils.getCloserVector3(world, front, self:getBackReference()) == front
end

Rig15.isAtRight = function(self: __object, world: Vector3):boolean
	local right = self:getRightReference()
	
	return Vector3Utils.getCloserVector3(world, right, self:getLeftReference()) == right
end

return Rig15
