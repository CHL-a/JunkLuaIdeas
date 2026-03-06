local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>
type dict<T> = Map.dictionary<T>

export type object = {
	character: Model;
	enabled: boolean;
	container: Folder;
	root: Weld;
	limbo: Folder;
	humanoid: Humanoid;
	motor6ds: map<Motor6D, Instance>;
	pseudo_collisions: {BasePart};
	limbs: {BasePart};

	enable: (self:object)->(); 
	disable: (self:object)->();
	toggle_outer_collisions: (self: object, is_tangible: boolean) -> ();
	create_pseudo_collision: (self: object, b:BasePart, size:Vector3?) -> BasePart;
}

-- CLASS
local Ragdollable = {}
local InstanceUtils = require('./@CHL>InstanceUtils')
local TableUtils = require('./@CHL>TableUtils')

local PhysicsService = game:GetService('PhysicsService')

imprint = TableUtils.imprint
create = InstanceUtils.create
disguise = require('./LuaUTypes').disguise

--#######################################################################################################################################
--#######################################################################################################################################
--#######################################################################################################################################

local RagdollJointInfo: {
	r15: dict<r15_limb_struct>
}

export type attachment_properties = {
	Orientation: Vector3?;
	Position: Vector3;
}

export type constraint_properties = {
	LimitsEnabled: boolean;
	TwistLimitsEnabled: boolean?;
	UpperAngle: number?;
	TwistLowerAngle: number?;
	TwistUpperAngle: number?;
	LowerAngle: number?;
}

export type r15_limb_struct = {
	limb1: string;
	limb2: string;
	attachment1: string?;
	properties: constraint_properties?;
	class: 'BallSocketConstraint' | 'HingeConstraint'
}

RagdollJointInfo = {
	r15 = {
		-- left leg
		LeftAnkleRigAttachment = {
			limb1 = 'LeftFoot',
			limb2 = 'LeftLowerLeg';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 40;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -30;
				TwistUpperAngle = 30
			}
		};

		LeftKneeRigAttachment = {
			limb1 = 'LeftLowerLeg';
			limb2 = 'LeftUpperLeg';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 135;
				LowerAngle = 0;
			}
		};

		LeftHipRigAttachment = {
			limb1 = 'LeftUpperLeg';
			limb2 = 'LowerTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 70;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -95;
				TwistUpperAngle = 25;
			}
		};

		-- right leg
		RightAnkleRigAttachment = {
			limb1 = 'RightFoot';
			limb2 = 'RightLowerLeg';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 40;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -30;
				TwistUpperAngle = 30
			}
		};

		RightKneeRigAttachment = {
			limb1 = 'RightLowerLeg';
			limb2 = 'RightUpperLeg';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 135;
				LowerAngle = 0;
			}
		};

		RightHipRigAttachment = {
			limb1 = 'RightUpperLeg';
			limb2 = 'LowerTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 70;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -25;
				TwistUpperAngle = 95;
			}
		};

		-- left arm
		LeftWristRigAttachment = {
			limb1 = 'LeftHand';
			limb2 = 'LeftLowerArm';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -95;
				TwistUpperAngle = 95
			}
		};

		LeftElbowRigAttachment = {
			limb1 = 'LeftLowerArm';
			limb2 = 'LeftUpperArm';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				LowerAngle = -135;
			}
		};

		LeftShoulderRigAttachment = {
			limb1 = 'LeftUpperArm';
			limb2 = 'UpperTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 15;
				TwistLowerAngle = -135;
				TwistLimitsEnabled = true;
				TwistUpperAngle = 135;
			}
		};

		-- right arm
		RightWristRigAttachment = {
			limb1 = 'RightHand';
			limb2 = 'RightLowerArm';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -95;
				TwistUpperAngle = 95
			}
		};

		RightElbowRigAttachment = {
			limb1 = 'RightLowerArm';
			limb2 = 'RightUpperArm';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				LowerAngle = -135;
			}
		};

		RightShoulderRigAttachment = {
			limb1 = 'RightUpperArm';
			limb2 = 'UpperTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 15;
				TwistLowerAngle = -135;
				TwistLimitsEnabled = true;
				TwistUpperAngle = 135;
			}
		};

		-- waist
		WaistRigAttachment = {
			limb1 = 'UpperTorso';
			limb2 = 'LowerTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 0;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -0;
				TwistUpperAngle = 0;
			}
		};

		-- neck
		NeckRigAttachment = {
			limb1 = 'UpperTorso';
			limb2 = 'Head';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 40;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -45;
				TwistUpperAngle = 45;
			};
		};
	};
}

--#######################################################################################################################################
--#######################################################################################################################################
--#######################################################################################################################################

local Object = require('./Object')
local Class = require('./Class')

-- Functions
function get_no_collision(part0, part1)
	return create('NoCollisionConstraint', {
		Enabled = true;
		Part0 = part0;
		Part1 = part1;
		Parent = part0
	})
end

function get_pseudo_collision(part: BasePart, size: Vector3?)
	local p: BasePart = not size and part:Clone() or 
		Instance.new('Part')

	p:ClearAllChildren()

	imprint(p, {
		Size = size or part.Size * 1.01;
		Transparency = 1;-- .75;
		CollisionGroup = 'pseudo_collision';
		Massless = true;
		CanCollide = false;
		CanTouch = false;
	})

	create('Weld', {
		Part0 = p;
		Part1 = part;
		Parent = p;
	})

	p.Parent = part

	return p
end

-- Assignments
if not PhysicsService:IsCollisionGroupRegistered('characters') then
	PhysicsService:RegisterCollisionGroup('characters')
end

if not PhysicsService:IsCollisionGroupRegistered('pseudo_collision') then
	PhysicsService:RegisterCollisionGroup('pseudo_collision')
end

PhysicsService:CollisionGroupSetCollidable('characters','characters', true)
PhysicsService:CollisionGroupSetCollidable('characters','pseudo_collision', false)

tinsert = table.insert
get_descendant = InstanceUtils.find_first_descendant

function graphify_character(edges: {Motor6D}, nodes: {BasePart}, character: Model)
	tinsert(nodes, assert(character:FindFirstChild('Head')))
	tinsert(nodes, assert(character:FindFirstChild('UpperTorso')))
	tinsert(nodes, assert(character:FindFirstChild('LowerTorso')))
	tinsert(nodes, assert(character:FindFirstChild('HumanoidRootPart')))

	tinsert(nodes, assert(character:FindFirstChild('LeftUpperArm')))
	tinsert(nodes, assert(character:FindFirstChild('LeftUpperLeg')))
	tinsert(nodes, assert(character:FindFirstChild('LeftLowerArm')))
	tinsert(nodes, assert(character:FindFirstChild('LeftLowerLeg')))
	tinsert(nodes, assert(character:FindFirstChild('RightUpperArm')))
	tinsert(nodes, assert(character:FindFirstChild('RightUpperLeg')))
	tinsert(nodes, assert(character:FindFirstChild('RightLowerArm')))
	tinsert(nodes, assert(character:FindFirstChild('RightLowerLeg')))

	tinsert(nodes, assert(character:FindFirstChild('LeftHand')))
	tinsert(nodes, assert(character:FindFirstChild('RightHand')))
	tinsert(nodes, assert(character:FindFirstChild('LeftFoot')))
	tinsert(nodes, assert(character:FindFirstChild('RightFoot')))
	
	tinsert(edges, assert(get_descendant(character, 'Head', 'Neck')))
	tinsert(edges, assert(get_descendant(character, 'UpperTorso', 'Waist')))
	tinsert(edges, assert(get_descendant(character, 'LowerTorso', 'Root')))

	tinsert(edges, assert(get_descendant(character, 'LeftUpperArm', 'LeftShoulder')))
	tinsert(edges, assert(get_descendant(character, 'RightUpperArm', 'RightShoulder')))

	tinsert(edges, assert(get_descendant(character, 'LeftLowerArm', 'LeftElbow')))
	tinsert(edges, assert(get_descendant(character, 'RightLowerArm', 'RightElbow')))

	tinsert(edges, assert(get_descendant(character, 'LeftHand', 'LeftWrist')))
	tinsert(edges, assert(get_descendant(character, 'RightHand', 'RightWrist')))

	tinsert(edges, assert(get_descendant(character, 'LeftUpperLeg', 'LeftHip')))
	tinsert(edges, assert(get_descendant(character, 'RightUpperLeg', 'RightHip')))

	tinsert(edges, assert(get_descendant(character, 'LeftLowerLeg', 'LeftKnee')))
	tinsert(edges, assert(get_descendant(character, 'RightLowerLeg', 'RightKnee')))

	tinsert(edges, assert(get_descendant(character, 'LeftFoot', 'LeftAnkle')))
	tinsert(edges, assert(get_descendant(character, 'RightFoot', 'RightAnkle')))
end

function Ragdollable.new(model: Model)
	-- pre
	local hum = assert(model:FindFirstChildWhichIsA('Humanoid'))
	local humanoid_root_part = assert(model:FindFirstChild('HumanoidRootPart'))

	-- main
	local self: object = Object.simple.new(Ragdollable)
	local isR15 = hum.RigType == Enum.HumanoidRigType.R15
	
	assert(isR15)

	self.character = model
	self.pseudo_collisions = {}

	local container = Instance.new('Folder')
	container.Name = 'Ragdollable'
	container.Parent = model

	local limbo = Instance.new('Folder')
	limbo.Parent = game:GetService('ReplicatedStorage')
	limbo.Name = 'Limbo'

	local root_replica = Instance.new('Weld')

	local motor6Ds: map<Motor6D, Instance> = {}
	local baseParts

	hum.BreakJointsOnDeath = false;
	hum.RequiresNeck = false

	-- set up
	self.container = container
	self.root = root_replica
	self.limbo = limbo
	self.humanoid = hum
	self.enabled = false
	self.motor6ds = motor6Ds

	-- r15

	-- attachments
	local head = assert(model:FindFirstChild('Head'))
	local head_neck_attachment = head:FindFirstChild('NeckRigAttachment')

	if head_neck_attachment and head_neck_attachment:IsA('Attachment') and false then
		local clone = head_neck_attachment:Clone()
		clone.Name = 'NeckRigAttachment_M'
		clone.Orientation = Vector3.new(0, 90)
		clone.Parent = head
	end
	
	local upper_torso = model:FindFirstChild('UpperTorso')
	local upper_torso_neck_attachment = upper_torso:FindFirstChild('NeckRigAttachment')

	if upper_torso_neck_attachment and upper_torso_neck_attachment:IsA('Attachment') then
		local clone = upper_torso_neck_attachment:Clone()
		clone.Name = 'NeckRigAttachment_M'
		clone.Orientation = Vector3.new(0, 90)
		clone.Parent = upper_torso
	end

	-- joints
	for attachment_0_name, struct in RagdollJointInfo.r15 do
		local limb1 = model:FindFirstChild(struct.limb1)
		local limb2 = model:FindFirstChild(struct.limb2)

		if not (limb1 and limb2) then continue end
		assert(limb1:IsA('BasePart') and limb2:IsA('BasePart'))

		local attachment0 = limb1:FindFirstChild(attachment_0_name)
		local attachment1 = limb2:FindFirstChild(
			struct.attachment1 or attachment_0_name
		);

		if not (attachment0 and attachment1) then continue end
		assert(attachment0:IsA('Attachment') and attachment1:IsA('Attachment'))

		local properties = struct.properties or {}

		imprint(properties, {
			Attachment0 = attachment0;
			Attachment1 = attachment1;
			Parent = container;
			Name = `{limb1.Name}|{limb2.Name}`
		})

		imprint(create(struct.class, properties), properties)
	end

	-- m6ds for limbo
	local edges, nodes = {}, {}
	
	graphify_character(edges, nodes, model)
	
	for _, v: Motor6D in edges do
		motor6Ds[v] = v.Parent;
	end

	-- weld
	local lower_torso = assert(model:FindFirstChild('LowerTorso'))
	local root = assert(lower_torso:FindFirstChild('Root'))

	root_replica.C0 = root.C0
	root_replica.C1 = root.C1
	root_replica.Part0 = root.Part0
	root_replica.Part1 = root.Part1
	root_replica.Parent = limbo
	
	self.limbs = nodes

	-- set up intangibility for adjacent limbs
	local left_upper_leg = assert(model:FindFirstChild('LeftUpperLeg'))
	local right_upper_leg = assert(model:FindFirstChild('RightUpperLeg'))
	local left_foot = assert(model:FindFirstChild('LeftFoot'))
	local right_foot = assert(model:FindFirstChild('RightFoot'))
	local left_upper_arm = assert(model:FindFirstChild('LeftUpperArm'))
	local right_upper_arm = assert(model:FindFirstChild('RightUpperArm'))

	for _, v: NoCollisionConstraint in {
		get_no_collision(left_upper_leg, right_upper_leg),
		get_no_collision(left_upper_leg, upper_torso),
		get_no_collision(right_upper_leg, upper_torso),
		get_no_collision(left_foot, left_upper_leg),
		get_no_collision(right_foot, right_upper_leg),
		get_no_collision(left_upper_arm, head),
		get_no_collision(left_upper_arm, head)
		} do
		v.Parent = container
	end
	
	local left_lower_leg = assert(model:FindFirstChild('LeftLowerLeg'))
	local right_lower_leg = assert(model:FindFirstChild('RightLowerLeg'))
	
	-- inner box collision
	local c_left_upper_leg = self:create_pseudo_collision(left_upper_leg, Vector3.new(.497,1.437,.599))
	local c_right_upper_leg = self:create_pseudo_collision(right_upper_leg, Vector3.new(.497,1.437,.599))
	local c_left_lower_leg = self:create_pseudo_collision(left_lower_leg)
	local c_right_lower_leg = self:create_pseudo_collision(right_lower_leg)
	
	local left_lower_arm = assert(model:FindFirstChild('LeftLowerArm'))
	local right_lower_arm = assert(model:FindFirstChild('RightLowerArm'))

	local c_head = self:create_pseudo_collision(head)
	local c_left_upper_arm = self:create_pseudo_collision(left_upper_arm)
	local c_right_upper_arm = self:create_pseudo_collision(right_upper_arm)
	local c_left_lower_arm = self:create_pseudo_collision(left_lower_arm)
	local c_right_lower_arm = self:create_pseudo_collision(right_lower_arm)

	c_left_upper_leg.Weld.C1 = CFrame.new(-.0797891617,-.113166332,-6.86645508e-5,-1,
		4.94118613e-9,1.59974199e-17,4.94118613e-9,1,-3.23755711e-9,-3.19947902e-17,
		-3.23755711e-9,-1)
	c_right_upper_leg.Weld.C1 = CFrame.new(.0795812607,-.113166332,-6.86645508e-5,-1,
		4.94118613e-9,1.59974199e-17,4.94118613e-9,1,-3.23755711e-9,-3.19947902e-17,
		-3.23755711e-9,-1)
	
	local left_hand = assert(model:FindFirstChild('LeftHand'))
	local right_hand = assert(model:FindFirstChild('RightHand'))

	for _, v: NoCollisionConstraint in {
		-- left leg
		get_no_collision(self:create_pseudo_collision(left_foot), c_left_lower_leg),
		get_no_collision(c_left_lower_leg, c_left_upper_leg),
		get_no_collision(c_left_upper_leg, lower_torso),
		-- get_no_collision(cLeftUpperLeg, upperTorso),

		-- right leg
		get_no_collision(self:create_pseudo_collision(right_foot), c_right_lower_leg),
		get_no_collision(c_right_lower_leg, c_right_upper_leg),
		get_no_collision(c_right_upper_leg, lower_torso),
		-- get_no_collision(cRightUpperLeg, upperTorso),

		-- left arm
		get_no_collision(self:create_pseudo_collision(left_hand), c_left_lower_arm),
		get_no_collision(c_left_lower_arm, c_left_upper_arm),
		get_no_collision(c_left_upper_arm, upper_torso),

		-- get_no_collision(cLeftUpperArm, cHead),

		-- right arm
		get_no_collision(self:create_pseudo_collision(right_hand), c_right_lower_arm),
		get_no_collision(c_right_lower_arm, c_right_upper_arm),
		get_no_collision(c_right_upper_arm, upper_torso),
		-- get_no_collision(cRightUpperArm,cHead),

		-- torso and head
		get_no_collision(upper_torso, lower_torso),
		get_no_collision(upper_torso, c_head),

		-- other
		-- get_no_collision(cLeftUpperLeg, cRightUpperLeg),

		-- get_no_collision(result:create_pseudo_collision(rig.leftFoot), cLeftUpperLeg),
		-- get_no_collision(result:create_pseudo_collision(rig.rightFoot), cRightUpperLeg),

		} do
		v.Parent = container
		--end
	end

	for _, a in self.limbs do
		a.CollisionGroup = 'characters'
	end

	self:toggle_outer_collisions(false)

	return self
end

function Ragdollable.enable(self: object)
	-- pre
	if self.enabled then return end

	-- main
	self.humanoid.PlatformStand = true

	for v in self.motor6ds do
		v.Enabled = false
		-- v.Parent = self.limbo
	end

	self:toggle_outer_collisions(true)

	self.root.Parent = self.container

	self.enabled = true
end

function Ragdollable.disable(self: object)
	if not (self.enabled and self.humanoid.Health > 0)then return end

	-- main
	self.humanoid.PlatformStand = false

	for v, p in self.motor6ds do
		v.Enabled = true
	end

	self:toggle_outer_collisions(false)

	self.root.Parent = self.limbo

	self.enabled = false
end

function Ragdollable.toggle_outer_collisions(self: object, is_tangible: boolean)
	for _, v in self.pseudo_collisions do
		v.CanCollide = is_tangible
		v.CanTouch = is_tangible
	end
end

function Ragdollable.create_pseudo_collision(self: object, b:BasePart, size:Vector3?)
	local pC = get_pseudo_collision(b,size)
	tinsert(self.pseudo_collisions,pC)
	pC.Parent = self.container
	return pC
end

Class.make_proper_class(Ragdollable, '@CHL>Ragdollable>R15')

return Ragdollable
