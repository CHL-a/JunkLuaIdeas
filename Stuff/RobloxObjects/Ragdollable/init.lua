-- SPEC
local Objects = game:GetService('ReplicatedStorage').Objects
local Rig15 = require(Objects.Rig15)
local Rig6 = require(Objects.Rig6)

type __object = {
	character: Model;
	enabled: boolean;
	container: Folder;
	root:Weld;
	limbo: Folder;
	humanoid: Humanoid;
	motor6Ds: {[Motor6D]:Instance};
	pseudoCollisions: {BasePart};
	limbs: {BasePart};

	enable: (self:__object)->nil; 
	disable:(self:__object)->nil;
	toggleOuterCollisions: (self:__object,isTangible:boolean)->nil;
	createPseudoCollision:(self:__object,b:BasePart,size:Vector3?)->BasePart;
}
export type object = __object

-- CLASS
local Ragdollable = {}
local DashInterface = require(Objects.DashInterface)
local Dash = require(Objects.Dash) :: DashInterface.module
local TableUtils = require(Objects["@CHL/TableUtils"])
local disguise = require(Objects.LuaUTypes).disguise

local imprint = TableUtils.imprint
local create = Dash.compose(
	function(a, b)return Instance.new(a), b end,
	imprint
) :: <A>(string, {[string]: any}) -> A

local RagdollJointInfo = require(script.RagdollJointInfo)
local PhysicsService = game:GetService('PhysicsService')

-- Functions
local function getNoCollision(part0, part1)
	return create('NoCollisionConstraint', {
		Enabled = true;
		Part0 = part0;
		Part1 = part1;
		Parent = part0
	})
end

local function getPseudoCollision(part: BasePart, size: Vector3?)
	local p: BasePart = not size and part:Clone() or 
		Instance.new('Part')
	
	p:ClearAllChildren()
	
	imprint(p, {
		Size = size or part.Size * 1.01;
		Transparency = 1;-- .75;
		CollisionGroup = 'pseudoCollision';
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

if not PhysicsService:IsCollisionGroupRegistered('pseudoCollision') then
	PhysicsService:RegisterCollisionGroup('pseudoCollision')
end

PhysicsService:CollisionGroupSetCollidable('characters','characters', true)
PhysicsService:CollisionGroupSetCollidable('characters','pseudoCollision', false)

Ragdollable.__index = Ragdollable

function Ragdollable.new(model: Model)
	-- pre
	local hum = assert(model:FindFirstChildWhichIsA('Humanoid'))
	local humanoidRootPart = assert(model:FindFirstChild('HumanoidRootPart'))
	
	-- main
	local self: __object = disguise(setmetatable({},Ragdollable))
	local isR15 = hum.RigType == Enum.HumanoidRigType.R15
	
	self.character = model
	self.pseudoCollisions = {}
	
	local container = Instance.new('Folder')
	container.Name = 'Ragdollable'
	container.Parent = model
	
	local limbo = Instance.new('Folder')
	limbo.Parent = game:GetService('ReplicatedStorage')
	limbo.Name = 'Limbo'
	
	local rootReplica = Instance.new('Weld')
	
	local motor6Ds: {[Motor6D]: Instance} = {}
	local baseParts
	
	hum.BreakJointsOnDeath = false;
	hum.RequiresNeck = false
	
	-- set up
	self.container = container
	self.root = rootReplica
	self.limbo = limbo
	self.humanoid = hum
	self.enabled = false
	self.motor6Ds = motor6Ds
	
	if isR15 then
		-- r15
		local rig = Rig15.new(model)
		
		-- attachments
		local headNeckAttachment = rig.head:FindFirstChild('NeckRigAttachment')
		
		if headNeckAttachment and headNeckAttachment:IsA('Attachment') and false then
			local clone = headNeckAttachment:Clone()
			clone.Name = 'NeckRigAttachment_M'
			clone.Orientation = Vector3.new(0, 90)
			clone.Parent = rig.head
		end
		
		local upperTorsoNeckAttachment = rig.upperTorso:FindFirstChild('NeckRigAttachment')

		if upperTorsoNeckAttachment and upperTorsoNeckAttachment:IsA('Attachment') then
			local clone = upperTorsoNeckAttachment:Clone()
			clone.Name = 'NeckRigAttachment_M'
			clone.Orientation = Vector3.new(0, 90)
			clone.Parent = rig.upperTorso
		end
		
		-- joints
		for attachment0Name, struct in next, RagdollJointInfo.r15 do
			local limb1 = model:FindFirstChild(struct.limb1)
			local limb2 = model:FindFirstChild(struct.limb2)
			
			if not (limb1 and limb2) then continue end
			assert(limb1:IsA('BasePart') and limb2:IsA('BasePart'))
			
			local attachment0 = limb1:FindFirstChild(attachment0Name)
			local attachment1 = limb2:FindFirstChild(
				struct.attachment1 or attachment0Name
			);
			
			if not (attachment0 and attachment1) then continue end
			assert(attachment0:IsA('Attachment') and attachment1:IsA('Attachment'))
			
			local properties = struct.properties or {}
			
			imprint(properties, {
				Attachment0 = attachment0;
				Attachment1 = attachment1;
				Parent = container;
				Name = limb1.Name .. '|' .. limb2.Name;
			})
			
			imprint(create(struct.class, properties), properties)
		end
		
		-- m6ds for limbo
		for _, v in next, rig:getMotor6Ds() do
			motor6Ds[v] = v.Parent;
		end
		
		-- weld
		local root = rig.root
		
		rootReplica.C0 = root.C0
		rootReplica.C1 = root.C1
		rootReplica.Part0 = root.Part0
		rootReplica.Part1 = root.Part1
		rootReplica.Parent = limbo
		
		baseParts = rig:getLimbs()
		self.limbs = baseParts
		
		-- set up intangibility for adjacent limbs
		for _, v: NoCollisionConstraint in next, {
			getNoCollision(rig.leftUpperLeg, rig.rightUpperLeg),
			getNoCollision(rig.leftUpperLeg, rig.upperTorso),
			getNoCollision(rig.rightUpperLeg, rig.upperTorso),
			getNoCollision(rig.leftFoot, rig.leftUpperLeg),
			getNoCollision(rig.rightFoot, rig.rightUpperLeg),
			getNoCollision(rig.leftUpperArm, rig.head),
			getNoCollision(rig.rightUpperArm,rig.head)
			} do
			v.Parent = container
		end
		-- inner box collision
		--if not rig.leftFoot.CanCollide then 
		local cLeftUpperLeg = self:createPseudoCollision(
			rig.leftUpperLeg,
			Vector3.new(.497,1.437,.599)
		)
		local cRightUpperLeg = self:createPseudoCollision(
			rig.rightUpperLeg,
			Vector3.new(.497,1.437,.599)
		)
		local cLeftLowerLeg = self:createPseudoCollision(rig.leftLowerLeg)
		local cRightLowerLeg = self:createPseudoCollision(rig.rightLowerLeg)
		
		local upperTorso = rig.upperTorso
		local lowerTorso = rig.lowerTorso
		local cHead = self:createPseudoCollision(rig.head)
		local cLeftUpperArm = self:createPseudoCollision(rig.leftUpperArm)
		local cRightUpperArm = self:createPseudoCollision(rig.rightUpperArm)
		local cLeftLowerArm = self:createPseudoCollision(rig.leftLowerArm)
		local cRightLowerArm = self:createPseudoCollision(rig.rightLowerArm)
		
		cLeftUpperLeg.Weld.C1 = CFrame.new(-.0797891617,-.113166332,-6.86645508e-5,-1,
			4.94118613e-9,1.59974199e-17,4.94118613e-9,1,-3.23755711e-9,-3.19947902e-17,
			-3.23755711e-9,-1)
		cRightUpperLeg.Weld.C1 = CFrame.new(.0795812607,-.113166332,-6.86645508e-5,-1,
			4.94118613e-9,1.59974199e-17,4.94118613e-9,1,-3.23755711e-9,-3.19947902e-17,
			-3.23755711e-9,-1)
		
		for _, v: NoCollisionConstraint in next, {
			-- left leg
			getNoCollision(self:createPseudoCollision(rig.leftFoot), cLeftLowerLeg),
			getNoCollision(cLeftLowerLeg, cLeftUpperLeg),
			getNoCollision(cLeftUpperLeg, lowerTorso),
			-- getNoCollision(cLeftUpperLeg, upperTorso),
			
			-- right leg
			getNoCollision(self:createPseudoCollision(rig.rightFoot), cRightLowerLeg),
			getNoCollision(cRightLowerLeg, cRightUpperLeg),
			getNoCollision(cRightUpperLeg, lowerTorso),
			-- getNoCollision(cRightUpperLeg, upperTorso),
			
			-- left arm
			getNoCollision(self:createPseudoCollision(rig.leftHand), cLeftLowerArm),
			getNoCollision(cLeftLowerArm, cLeftUpperArm),
			getNoCollision(cLeftUpperArm, upperTorso),
			
			-- getNoCollision(cLeftUpperArm, cHead),
			
			-- right arm
			getNoCollision(self:createPseudoCollision(rig.rightHand), cRightLowerArm),
			getNoCollision(cRightLowerArm, cRightUpperArm),
			getNoCollision(cRightUpperArm, upperTorso),
			-- getNoCollision(cRightUpperArm,cHead),
			
			-- torso and head
			getNoCollision(upperTorso, lowerTorso),
			getNoCollision(upperTorso, cHead),
			
			-- other
			-- getNoCollision(cLeftUpperLeg, cRightUpperLeg),
			
			-- getNoCollision(result:createPseudoCollision(rig.leftFoot), cLeftUpperLeg),
			-- getNoCollision(result:createPseudoCollision(rig.rightFoot), cRightUpperLeg),
			
			} do
			v.Parent = container
			--end
		end
	else
		error('unimplemented')
	end
	
	for _, a in next, baseParts do
		a.CollisionGroupId = 0
		a.CollisionGroup = 'characters'
		--a.CanTouch = false
	end
	
	self:toggleOuterCollisions(false)
	
	return self
end

Ragdollable.enable = function(self:__object)
	-- pre
	if self.enabled then return end

	-- main
	self.humanoid.PlatformStand = true

	for v in next, self.motor6Ds do
		v.Enabled = false
		-- v.Parent = self.limbo
	end
	
	self:toggleOuterCollisions(true)
	
	self.root.Parent = self.container

	self.enabled = true
end

Ragdollable.disable = function(self:__object)
	if not (self.enabled and self.humanoid.Health > 0)then return end

	-- main
	self.humanoid.PlatformStand = false

	for v, p in next, self.motor6Ds do
		v.Enabled = true
	end

	self:toggleOuterCollisions(false)
	
	self.root.Parent = self.limbo

	self.enabled = false
end

Ragdollable.toggleOuterCollisions = function(self:__object,isTangible:boolean)
	for _, v in next, self.pseudoCollisions do
		v.CanCollide = isTangible
		v.CanTouch = isTangible
	end
end

Ragdollable.createPseudoCollision = function(self:__object,b:BasePart,size:Vector3?)
	local pC = getPseudoCollision(b,size)
	table.insert(self.pseudoCollisions,pC)
	pC.Parent = self.container
	return pC
end

return Ragdollable
