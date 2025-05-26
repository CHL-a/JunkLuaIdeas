-- SPEC
local CharacterRig = require('./@CHL>CharacterRig')
local Class = require('./Class')
local IKCollection = require('./@CHL>IKCollection')
local ProceduralLeg = require('./@CHL>ProceduralLeg')
local RuntimeUpdater = require('./@CHL>RuntimeUpdater')
local Spring = require('./@CHL>Spring')
local Destructable = require('./@CHL>Destructable')
local ResponsiveCache = require('./@CHL>ResponsiveCache')
local Dash = require('./@CHL>DashSingular')

type map<I, V> = Dash.Map<I, V>
type set<A> = Dash.Set<A>
type __side = 'Left' | 'Right'

export type object = {
	-- States
	__constructorArg: constructorArgs;
	
	-- nodes
	nodes: {node};
	
	head: node;
	upperTorso: node;
	lowerTorso: node;
	humanoidRootPart: node;

	rightUpperLeg: node;
	rightLowerLeg: node;
	rightFoot: node;

	leftUpperLeg: node;
	leftLowerLeg: node;
	leftFoot: node;

	rightUpperArm: node;
	rightLowerArm: node;
	rightHand: node;

	leftUpperArm: node;
	leftLowerArm: node;
	leftHand: node;

	-- edges
	edges: {edge};
	
	neck: edge;
	waist: edge;
	root: edge;
	
	rightGrip: gripEdge;
	rightWrist: edge;
	rightElbow: edge;
	rightShoulder: edge;
	
	leftGrip: gripEdge;
	leftWrist: edge;
	leftElbow: edge;
	leftShoulder: edge;
	
	rightAnkle: edge;
	rightKnee: edge;
	rightHip: edge;
	
	leftAnkle: edge;
	leftKnee: edge;
	leftHip: edge;
	
	-- animations
	animator: Animator;
	
	ikCollection: IKCollection.object;
	rightFootTarget: Attachment;
	leftFootTarget: Attachment;
	leftHandTarget: Attachment;
	rightHandTarget: Attachment;
	walker: __walker;
	
	-- Methods
	__setNode: (self: object, string) -> node;
	__setEdge: (self: object, string) -> edge;
	
	getMotor6Ds: (self:object) -> {Motor6D};
	getLimbs: (self:object) -> {BasePart};
	isAtFront: (self:object, world: Vector3) -> boolean;
	getRelativeVelocity: (self: object) -> Vector3;
	getAngleRelativeToFloor: (self: object, epsilon: number) -> (number, boolean);
	getFrontReference: (self:object) -> Vector3;
	getBackReference: (self:object) -> Vector3;
	getLeftReference: (self:object) -> Vector3;
	getRightReference: (self: object) -> Vector3;
	isAtRight: (self:object, world: Vector3) -> Vector3;
	getWorldPosFromRelative: (self:object, Vector3) -> Vector3;
	getHRPElevation: (self:object) -> number;
	repairGraph: (self: object) -> boolean;
	getCoreSound: (self: object, s: string) -> Sound;
} & Class.subclass<CharacterRig.object>
  & Destructable.object

export type constructorArgs = {
	loadWalker: boolean?;
} & CharacterRig.constructorArgs

-- CLASS
local Rig15 = {}
local LuaUTypes = require('./LuaUTypes')
local TableUtils = require('./@CHL>TableUtils')
local InstanceUtils = require('./@CHL>InstanceUtils')
local Vector3Utils = require('./@CHL>Vector3Utils')
local StringUtils = require('./@CHL>StringUtils')

camelCaseify = StringUtils.camelCaseify
disguise = LuaUTypes.disguise
compose = Dash.compose
imprint = TableUtils.imprint
create = InstanceUtils.create
push = TableUtils.push
valueSet = TableUtils.valueSet

sides = {'Left', 'Right'}
limbs = {'Arm', 'Leg'}
sections = {'Upper','Lower'}
isClient = game:GetService('RunService'):IsClient()
pi = math.pi
vFloor = Vector3.new(1,0,1)

--#########################################################################################
--#########################################################################################
--#########################################################################################

local Object = require('./Object')

type __walkState = 'idle' | 'forward' | 'backward' | 'left' | 'right'

type __walker = {
	leftLeg: ProceduralLeg.object;
	rightLeg: ProceduralLeg.object;
	isUsingLeft: boolean;
	rightStep: Vector3;
	leftStep: Vector3;
	rig: object;
	walkingState: __walkState;
	enabled: boolean;
	enable: (self: __walker, boolean) -> ();
} & RuntimeUpdater.updatable
  & Object.object_inheritance

local Walker = {}

Walker.hoverPositions = {
	idle     = {left = Vector3.new(-.5)     ;right = Vector3.new(.5)     };
	forward  = {left = Vector3.new(-.5,0,-1);right = Vector3.new(.5,0,-1)};
	backward = {left = Vector3.new(-.5,0,1) ;right = Vector3.new(.5,0,1)};
	right    = {left = Vector3.new(1,0,-.75);right = Vector3.new(1.25)};
	left     = {left = Vector3.new(-1.25)   ;right = Vector3.new(-1,0,-.75)}
}

function Walker.new(rig: object): __walker
	local self: __walker = Object.from.class(Walker)
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

function Walker.enable(self:__walker, b: boolean)
	local rig = self.rig :: object

	self.enabled = b;

	self.rightLeg.iKControl.Enabled = b
	self.leftLeg.iKControl.Enabled = b
end

function Walker.update(self: __walker, dt: number)
	local rightLeg = self.rightLeg
	local leftLeg = self.leftLeg
	local rig = self.rig::object
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
	
	--if workspace.updateHover.Value then
		leftLeg.targetHover.Position, rightLeg.targetHover.Position = 
			convertHoverPosition(walkingState, y)
	--end
	
	-- update springs
	rightLeg:update(dt)
	leftLeg:update(dt)
	
	-- check step sides
	if 
		-- workspace.updateHover.Value and
		not (leftSpringP:FuzzyEq(leftT, .01) and rightSpringP:FuzzyEq(rightT, .01)) then
		return
	end
	
	local referral: Vector3 = nil

	-- get reference for compare
	if walkingState == 'left' or walkingState == 'right' then
		local hrpP = rig:getWorldPosFromRelative(Vector3.zero)
		local far = rig:getWorldPosFromRelative(
			Vector3.xAxis * (walkingState ~= 'right' and 1 or -1))

		local leftLegAtFar = Vector3Utils.getCloserVector3(leftT, hrpP, far) == far
		local rightLegAtFar = Vector3Utils.getCloserVector3(rightT, hrpP, far) == far

		if not leftLegAtFar and not rightLegAtFar then
			referral = walkingState == 'right' and 
				rig:getRightReference() or 
				rig:getLeftReference()
		end
	else
		local leftLegZ = rig:isAtFront(leftT)
		local isOnSameZ = leftLegZ == rig:isAtFront(rightT)

		if isOnSameZ and (not leftLegZ) == (walkingState ~= 'backward') then
			referral = not leftLegZ and 
				rig:getBackReference() or 
				rig:getFrontReference()
		end
	end

	-- update the step that is the closest
	if not referral then return end
	
	if Vector3Utils.getCloserVector3(
		referral, leftT, rightT) == leftT then
		leftLeg:updateStep()
	else
		rightLeg:updateStep()
	end
end

Class.makeProperClass(Walker, '@CHL>Rig15>Walker')

--#########################################################################################
--#########################################################################################
--#########################################################################################

type __attachmentMap = map<string, true | (n: node, name: string) -> Attachment>

export type node_arg = {
	attachmentPresence: __attachmentMap;
	name: string;
	rig: object;
}

export type node = {
	name: string;
	basePart: BasePart;
	rig: object;
	attachments: map<string, Attachment>;
	attachmentPresence: __attachmentMap;
	
	edges: map<string, edge>;
	
	repair: (self: node) -> boolean;
} & Object.object_inheritance

local Node = {}

function Node.new(arg: node_arg) : node
	local self: node = Object.from.class(Node)
	self.name = arg.name
	self.attachments = {}
	self.attachmentPresence = arg.attachmentPresence
	self.rig = arg.rig
	self.edges = {}
	
	self:repair()
	
	return self
end

function Node.repair(self: node)
	local rig = self.rig;
	local character = rig.character
	local basePart = self.basePart
	local attachments = self.attachments
	local result = true
	
	if not (self.basePart and self.basePart:IsDescendantOf(game)) then
		basePart = rig:__getDescendantFromArg(self.name)
		self.basePart = basePart
		result = false;
	end
	
	for a, ref in next, self.attachmentPresence do
		local at = attachments[a]
		
		if (at and at:IsDescendantOf(game))then continue;end
		
		if isClient or ref == true then
			at = rig:__getDescendantFromArg(self.name, a)
		else
			at = ref(self, a)
		end
		
		attachments[a] = at
		result = false
	end
	
	return result;
end

-- presences
Node.attachmentPresences = {
	head = valueSet(('FaceCenterAttachment,FaceFrontAttachment,HairAttachment,\z
		HatAttachment,NeckRigAttachment'):split(','));
	upperTorso = valueSet(('BodyBackAttachment,BodyFrontAttachment,LeftCollarA\z
		ttachment,LeftShoulderRigAttachment,NeckAttachment,NeckRigAttachment\z
		,RightCollarAttachment,RightShoulderRigAttachment,WaistRigAttachment')
		:split',');
	lowerTorso = valueSet(('LeftHipRigAttachment,RightHipRigAttachment,RootRig\z
		Attachment,WaistBackAttachment,WaistCenterAttachment,WaistFrontAttac\z
		hment,WaistRigAttachment'):split(','));
	humanoidRootPart = valueSet(('RootAttachment,RootRigAttachment'):split',');
	
	leftUpperArm = valueSet(('LeftElbowRigAttachment,LeftShoulderAttachment,Le\z
		ftShoulderRigAttachment'):split',');
	leftLowerArm = valueSet(('LeftElbowRigAttachment,LeftWristRigAttachment'):
		split',');
	leftHand = valueSet(('LeftWristRigAttachment,LeftGripAttachment'):split',');
	
	rightUpperArm = valueSet(('RightElbowRigAttachment,RightShoulderAttachment\z
		,RightShoulderRigAttachment'):split',');
	rightLowerArm = valueSet(('RightElbowRigAttachment,RightWristRigAttachment')
		:split',');
	rightHand=valueSet(('RightWristRigAttachment,RightGripAttachment'):split',')
	;
	
	leftUpperLeg = valueSet(('LeftHipRigAttachment,LeftKneeRigAttachment'):split
		',');
	leftLowerLeg=valueSet(('LeftKneeRigAttachment,LeftAnkleRigAttachment'):split
		',');
	leftFoot = valueSet(('LeftAnkleRigAttachment,LeftFootAttachment'):split',');
	
	rightUpperLeg = valueSet(('RightHipRigAttachment,RightKneeRigAttachment'):
		split',');
	rightLowerLeg = valueSet(('RightKneeRigAttachment,RightAnkleRigAttachment'):
		split',');
	rightFoot=valueSet(('RightAnkleRigAttachment,RightFootAttachment'):split',')
	;
}

local presence = Node.attachmentPresences

function cloneAttachment90(node: node, name: string)
	local alt = name:gsub('Constraint', 'Rig')
	local ref = node.basePart:FindFirstChild(alt)
	local clone: Attachment = ref:Clone()
	clone.Orientation = Vector3.zAxis * 90
	clone.Name = name
	clone.Parent = ref.Parent
	return clone
end

function soleAttachment(node: node, name: string)
	local at = Instance.new('Attachment')
	at.Position = Vector3.new(0, node.basePart.Size.Y/-2)
	at.Name = name;
	at.Parent = node.basePart
	return at
end

Rig15.Node = Node;
Class.makeProperClass(Node, '@CHL>Rig15>Node')

presence.head.NeckConstraintAttachment = cloneAttachment90

presence.upperTorso.NeckConstraintAttachment = cloneAttachment90
presence.upperTorso.WaistConstraintAttachment = cloneAttachment90
presence.upperTorso.LeftShoulderConstraintAttachment=cloneAttachment90
presence.upperTorso.RightShoulderConstraintAttachment=cloneAttachment90

presence.lowerTorso.WaistConstraintAttachment = cloneAttachment90
presence.lowerTorso.LeftHipConstraintAttachment=cloneAttachment90
presence.lowerTorso.RightHipConstraintAttachment=cloneAttachment90

presence.leftUpperArm.LeftShoulderConstraintAttachment=cloneAttachment90
presence.leftLowerArm.LeftWristConstraintAttachment=cloneAttachment90
presence.leftHand.LeftWristConstraintAttachment=cloneAttachment90

presence.rightUpperArm.RightShoulderConstraintAttachment=cloneAttachment90
presence.rightLowerArm.RightWristConstraintAttachment=cloneAttachment90
presence.rightHand.RightWristConstraintAttachment=cloneAttachment90

presence.leftUpperLeg.LeftHipConstraintAttachment=cloneAttachment90
presence.leftLowerLeg.LeftAnkleConstraintAttachment=cloneAttachment90
presence.leftFoot.LeftAnkleConstraintAttachment=cloneAttachment90
presence.leftFoot.LeftSole = soleAttachment

presence.rightUpperLeg.RightHipConstraintAttachment=cloneAttachment90
presence.rightLowerLeg.RightAnkleConstraintAttachment=cloneAttachment90
presence.rightFoot.RightAnkleConstraintAttachment=cloneAttachment90
presence.rightFoot.RightSole = soleAttachment

--#########################################################################################
--#########################################################################################
--#########################################################################################
type __constraintStruct = {
	properties: {
		LowerAngle: number?;
		UpperAngle: number;
		TwistLowerAngle: number?;
		TwistUpperAngle: number?;
	};
	class: 'HingeConstraint' | 'BallSocketConstraint';
	attachmentName: string
}

export type edge_constructor_arg = {
	name: string;
	rig: object;
	endPoints: {node};
	constraintsReference: map<string, __constraintStruct>;
}

export type edge = {
	name: string;
	rig: object;
	motor6D: Motor6D;
	constraints: map<string, Constraint>;
	constraintReference: map<string, __constraintStruct>;
	endPoints: {node};
	
	repair: (self: edge) -> boolean;
} & Object.object_inheritance

local Edge = {}

function Edge.new(arg: edge_constructor_arg): edge
	local self: edge = Object.new():__inherit(Edge)
	self.name = arg.name;
	self.rig = arg.rig
	self.constraints = {}
	self.constraintReference = arg.constraintsReference
	self.endPoints = arg.endPoints
	
	for i = 1, 2 do
		local n = self.endPoints[i]
		n.edges[self.name] = self
	end
	
	self:repair()
	
	return self
end

function Edge.repair(self: edge)
	local result = true
	local node0, node1 = unpack(self.endPoints)
	local rig = self.rig
	
	local motor6d = self.motor6D
	if not (motor6d and motor6d:IsDescendantOf(game)) then
		motor6d = rig:__getDescendantFromArg(node1.name, self.name)
		self.motor6D = motor6d
		result = false
	end
	
	for a, ref: __constraintStruct in self.constraintReference do
		local con = self.constraints[a]
		
		if (con and con:IsDescendantOf(game)) then continue;end
		
		if isClient then
			con = rig:__getDescendantFromArg(node1.name, self.name)
		else
			con = Instance.new(ref.class)
			con.LimitsEnabled = true
			
			if ref.class == 'HingeConstraint' then
				imprint(con, ref.properties)
			else
				con.UpperAngle = ref.properties.UpperAngle
				
				local low = ref.properties.TwistLowerAngle
				
				if low then
					con.TwistLimitsEnabled = true
					con.TwistLowerAngle = low
					con.TwistUpperAngle = ref.properties.TwistUpperAngle or -low
				end
			end
			
			con.Attachment1 = node1.attachments[ref.attachmentName]
			con.Attachment0 = node0.attachments[ref.attachmentName]
			con.Name = a
			con.Parent = node1.basePart
		end
		
		self.constraints[a] = con
		
		result = false
	end
	
	return result
end

function getBallSocket(atName: string, upperangle: number, tlower:number?, tupper: number?)
	return {
		attachmentName = atName;
		class = 'BallSocketConstraint';
		properties = {
			UpperAngle = upperangle;
			TwistLowerAngle = tlower;
			TwistUpperAngle = tupper
		}
	} :: __constraintStruct
end

function getHinge(atName: string, lower: number, upper: number)
	return {
		attachmentName = atName;
		class = 'HingeConstraint';
		properties = {
			LowerAngle = lower;
			UpperAngle = upper;
		}
	} :: __constraintStruct
end

local constraintInfo: map<string, map<string, __constraintStruct>> = {
	neck = {neckConstraint = getBallSocket('NeckConstraintAttachment', 30, -45);};
	waist = {waistConstraint = getBallSocket('WaistConstraintAttachment', 15, -1)};
	root = {};
	
	leftShoulder = {
		leftShoulderConstraint=getBallSocket('LeftShoulderRigAttachment',30,-60)};
	leftElbow = {leftElbowConstraint=getHinge('LeftElbowRigAttachment', 0, 135)};
	leftWrist={leftWristConstraint=getBallSocket('LeftWristConstraintAttachment',30,-45)};
	
	rightShoulder = {
		rightShoulderConstraint=getBallSocket('RightShoulderRigAttachment',30,-60)};
	rightElbow = {rightElbowConstraint=getHinge('RightElbowRigAttachment', 0, 135)};
	rightWrist={rightWristConstraint=getBallSocket('RightWristConstraintAttachment',30,-45)};
	
	leftHip = {leftHipConstraint = getBallSocket('LeftHipConstraintAttachment', 45, -45)};
	leftKnee = {leftKneeConstraint = getHinge('LeftKneeRigAttachment', -135, 0)};
	leftAnkle={leftAnkleConstraint=getBallSocket('LeftAnkleConstraintAttachment',-135,0)};

	rightHip = {rightHipConstraint = getBallSocket('RightHipConstraintAttachment',45,-45)};
	rightKnee = {rightKneeConstraint = getHinge('RightKneeRigAttachment', -135, 0)};
	rightAnkle = {
		rightAnkleConstraint = getBallSocket('RightAnkleConstraintAttachment',-135,0)};
}

Edge.constraintInfo = constraintInfo
Rig15.Edge = Edge;
Class.makeProperClass(Edge, '@CHL>Rig15>Edge')

--#########################################################################################
--#########################################################################################
--#########################################################################################

export type grip_edge_args = {
	name: string;
	rig: object;
	endPoint: node;
	constraintsReference: map<string, __constraintStruct>?;
}

export type gripEdge = { 
	args: grip_edge_args;
} & edge 

local GripEdge = {}

function GripEdge.new(args: grip_edge_args)
	local self: gripEdge = Object.new():__inherit(GripEdge)
	self.args = args
	self.rig = args.rig
	self.name = args.name
	self.constraints = {}
	self.constraintReference = args.constraintsReference or {}
	self.endPoints = {args.endPoint}
	
	self.endPoints[1].edges[self.name] = self
	
	self:repair()
	
	return self
end

function GripEdge.repair(self: gripEdge)
	local result = true
	
	if not (self.motor6D and self.motor6D:IsDescendantOf(game)) then
		local m6d = self.endPoints[1].basePart:FindFirstChild(self.name)
		
		if not m6d then
			m6d = Instance.new('Motor6D')
			local part0 = self.endPoints[1].basePart
		
			m6d.Name = self.name
			m6d.Part0 = part0
			m6d.Parent = part0
		end
		
		self.motor6D = m6d
		result = false
	end
	
	return result
end

Class.makeProperClass(GripEdge, '@CHL>Rig15>GripEdge')
Rig15.gripEdge = GripEdge

--#########################################################################################
--#########################################################################################
--#########################################################################################

function __setGraph(self: object)
	-- set nodes
	self.nodes = {
		self:__setNode('Head'),
		self:__setNode('UpperTorso'),
		self:__setNode('LowerTorso'),
		self:__setNode('HumanoidRootPart')
	}
	
	for _, a in sides do
		for _, b in sections do
			for _, c in limbs do
				push(self.nodes, self:__setNode(`{a}{b}{c}`))
			end
		end
		
		push(self.nodes,
			self:__setNode(`{a}Hand`),
			self:__setNode(`{a}Foot`)
		)
	end
	
	-- set edges
	self.edges = {
		self:__setEdge('Head.Neck'),
		self:__setEdge('UpperTorso.Waist'),
		self:__setEdge('LowerTorso.Root')
	}
	
	for _, a in sides do
		push(self.edges, 
			self:__setEdge(`{a}UpperArm.{a}Shoulder`),
			self:__setEdge(`{a}LowerArm.{a}Elbow`),
			self:__setEdge(`{a}Hand.{a}Wrist`),
			
			self:__setEdge(`{a}UpperLeg.{a}Hip`),
			self:__setEdge(`{a}LowerLeg.{a}Knee`),
			self:__setEdge(`{a}Foot.{a}Ankle`)
		)
		
		local gripNode = disguise(self)[`{camelCaseify(a)}Hand`]
		
		local grip = GripEdge.new{
			name = `{a}Grip`;
			rig = self;
			endPoint = gripNode;
		}
		
		disguise(self)[camelCaseify(a)] = grip
	end
end

function __getFootIKControl(chainRoot: BasePart, endEffector: Attachment, 
	name: string, parent: Instance)
	local footIKC = imprint(Instance.new('IKControl'), {
		Enabled = false;
		ChainRoot = chainRoot; -- upperLeg;
		EndEffector = endEffector; -- sole
		Name = name
	})
	footIKC.Parent = parent
	return footIKC
end

function __getFootTarget(a: string, b: string, hrp: BasePart, elevation: number)
	local footTarget = imprint(Instance.new('Attachment'),{
		Position = Vector3.new(
			(a == 'Right' and 1 or -1)  * .8,
			-elevation
		);
		Name = `__{b}FootTarget`
	})
	footTarget.Parent = hrp
	return footTarget
end

function __getHandIKControl(footIKC: IKControl, upperArm, hand, handName, humanoid)
	local handIKC = imprint(footIKC:Clone(),{
		ChainRoot = upperArm;
		EndEffector = hand;
		Name = handName;
	})
	handIKC:ClearAllChildren()
	handIKC.Parent = humanoid
	
	return handIKC
end

function __getHandTarget(a, b, hrp)
	local handTarget = imprint(Instance.new('Attachment'), {
		Position = Vector3.new((a == 'Right' and 1 or -1) * 1, 0, -1);
		Orientation = Vector3.new(90);
		Name = `__{b}HandTarget`
	})
	handTarget.Parent = hrp
	return handTarget
end

local cache: ResponsiveCache.object<(object), (Model)> = ResponsiveCache.new(disguise)

function Rig15.new(char:Model, arg: constructorArgs?): object
	-- pre
	local cached = cache:exists(char);
	if cached then return cache:get(char) end
	
	-- main
	local self: object = CharacterRig.new(char, arg):__inherit(Rig15)
	local __self = disguise(self)
	local __arg = self.__constructorArg :: constructorArgs
	
	__setGraph(self)
	
	local hrp: node = self.humanoidRootPart
	hrp.basePart.CanCollide = true
	
	self.animator = self:__getDescendantFromArg('Humanoid', 'Animator')
	
	--ik control
	self.ikCollection = IKCollection.new()
	
	-- other states
	for _, a in sides do -- per side
		-- sole + inv kin + foot target + hand target
		local highFootName = `{a}Foot`
		local b = camelCaseify(a)

		local footName = `{b}Foot`
		
		local sole = (__self[footName] :: node).attachments[`{a}Sole`]
		
		local soleName = `{b}Sole`
		local handName = `{b}Hand`
		
		local foot = __self[footName]
		local hand = __self[handName]
		local lowerLeg = __self[`{b}LowerLeg`]
		local lowerArm = __self[`{b}LowerArm`]
		local upperLeg = __self[`{b}UpperLeg`]
		
		local footIKC = isClient and 
			self:__getDescendantFromArg('Humanoid', footName) or
			__getFootIKControl(upperLeg, sole, footName, self.humanoid)
		local footTarget = isClient and
			self:__getDescendantFromArg('HumanoidRootPart', `__{b}FootTarget`) or 
			__getFootTarget(a, b, hrp.basePart, self:getHRPElevation())
		
		local handIKC = isClient and 
			self:__getDescendantFromArg('Humanoid', handName) or 
			__getHandIKControl(footIKC, __self[`{b}UpperArm`], hand, handName, 
				self.humanoid)
		local handTarget = isClient and
			self:__getDescendantFromArg('HumanoidRootPart', `__{b}HandTarget`) or 
			__getHandTarget(a, b, hrp.basePart)
		
		
		if not isClient then
			-- feet
			footIKC.Target = footTarget;

			-- hands
			handIKC.Target = handTarget;
		end
		
		__self[`{footName}Target`] = footTarget
		__self[`{handName}Target`] = handTarget
		
		self.ikCollection:add(footIKC, handIKC)
	end
	
	self.ikCollection:enable(false)
	
	if __arg.loadWalker then
		self.walker = Walker.new(self)
	end
	
	cache.cache[ResponsiveCache.getIndex(char)] = {self}
	return self
end

function getWorldVectorFromRel(cf:CFrame,_,rel: Vector3, ...)
	return cf.Position+Vector3Utils.getRelativeVector(cf, rel)
end

function plusDefaultVect(a)
	return function(self: object)return self:getWorldPosFromRelative(a)end
end

function repairGraph_1(last, current: node | edge)
	local op = disguise(current):repair()
	return last and op
end

function getHumanoidRootPart(self:object,...)return self.humanoidRootPart.basePart,...end
function getPositionAndVelocity(p: Part,...)return p.CFrame,p.AssemblyLinearVelocity,...end

getNillessArray = compose(table.clone,TableUtils.clearNils)
getHrpPNV = compose(getHumanoidRootPart,getPositionAndVelocity)

Rig15.getRelativeVelocity = compose(getHrpPNV,Vector3Utils.getRelativeVector)
Rig15.getWorldPosFromRelative = compose(getHrpPNV,getWorldVectorFromRel)
Rig15.getFrontReference = plusDefaultVect(Vector3.zAxis)
Rig15.getBackReference = plusDefaultVect(-Vector3.zAxis)
Rig15.getRightReference = plusDefaultVect(Vector3.xAxis)
Rig15.getLeftReference = plusDefaultVect(-Vector3.xAxis)
Rig15.assertDestruction = Destructable.assertDestruction

function Rig15.getLimbs(self:object)
	return Dash.collectArray(self.nodes, function(a0: number, a1: node)
		return a1.name ~= 'HumanoidRootPart' and a1.basePart or nil
	end)
end

function Rig15.getMotor6Ds(self: object)
	return Dash.collectArray(self.edges, function(a0: number, a1: edge)
		return a1.motor6D
	end)
end

function Rig15.__setNode(self: object, n: string)
	local low = camelCaseify(n)
	local node = Node.new{
		name = n;
		rig = self;
		attachmentPresence = Node.attachmentPresences[low];
	}
	
	disguise(self)[low] = node
	return node
end

function Rig15.__setEdge(self: object, breadcrumb: string)
	local parent, name = unpack(breadcrumb:split('.'))
	local __self = disguise(self)
	local low = camelCaseify(name)
	local motor6D = __self.character[parent][name]
	local edge = Edge.new({
		name = name;
		rig = self;
		endPoints = disguise{
			__self[camelCaseify(motor6D.Part0.Name)], 
			__self[camelCaseify(motor6D.Part1.Name)]
		};
		constraintsReference = Edge.constraintInfo[low]
	})
	
	__self[low] = edge
	
	return edge
end

function Rig15.destroy(self: object)
	cache:decache(self.character)
	table.clear(self.nodes)
	table.clear(self.edges)
	self.isDestroyed = true;
end

function Rig15.getAngleRelativeToFloor(self: object, epsilon: number)
	local h = self.humanoidRootPart
	local v = h.AssemblyLinearVelocity * vFloor
	local c = h.CFrame
	
	return (c.LookVector * vFloor):Angle(v, Vector3.yAxis),
		v.Magnitude > epsilon
end

function Rig15.isAtFront(self: object, world: Vector3):boolean
	local front = self:getFrontReference()

	return Vector3Utils.getCloserVector3(world, front, self:getBackReference()) == front
end

function Rig15.isAtRight(self: object, world: Vector3):boolean
	local right = self:getRightReference()
	
	return Vector3Utils.getCloserVector3(world, right, self:getLeftReference()) == right
end

function Rig15.getHRPElevation(self:object)
	return self.humanoid.HipHeight + self.humanoidRootPart.basePart.Size.Y / 2
end

function Rig15.repairGraph(self: object)
	--print(self)
	return Dash.reduce(self.nodes, repairGraph_1, true) and 
		Dash.reduce(self.edges, repairGraph_1, true)
end

function Rig15.getCoreSound(self: object, s: string)
	return self.humanoidRootPart.basePart:FindFirstChild(s)
end

Class.makeProperClass(Rig15, '@CHL>Rig15')

return Rig15
