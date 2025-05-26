--// TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)
local Spring = require(Objects["@CHL/Spring"])
local RuntimeUpdater = require(Objects.RuntimeUpdater)

export type constructorArgs = {
	legJoints: {Attachment};
	foot: Attachment?;
	footTarget: Attachment;
	rayParams: RaycastParams;
	targetHover: Attachment?;
	iKControl: IKControl;
}

export type object ={
	hip: Attachment;
	foot: Attachment;
	footTarget: Attachment;
	shouldStep: boolean;
	legJoints: {Attachment};
	bigL: number;
	rayParams : RaycastParams;
	targetHover: Attachment;
	iKControl: IKControl;
	positionSpring: Spring.object<Vector3>;
	normalSpring: Spring.object<Vector3>;
	
	getBigL: (self: object) -> number;
	getSmallD: (self: object) -> number;
	getNewStep: (self: object) -> (Vector3, Vector3);
	updateStep: (self: object) -> ();
} & Class.subclass<Object.object>
  & RuntimeUpdater.updatable

--// MAIN
local module = {}
local Dash = require(Objects["@CHL/DashSingular"])
local Vector3Utils = require(Objects.Vector3Utils)

disguise = require(Objects.LuaUTypes).disguise

function module.new(arg: constructorArgs): object
	local self: object = Object.new():__inherit(module)
	local joints = arg.legJoints
	
	self.hip = joints[1]
	self.foot = Dash.last(joints)
	self.legJoints = arg.legJoints
	self.bigL = self:getBigL()
	self.canUpdate = true
	self.footTarget = arg.footTarget
	self.rayParams = arg.rayParams
	self.shouldStep = true
	self.iKControl = arg.iKControl
	-- self.step = self.foot.WorldPosition
	
	local pSpring = Spring.new(self.foot.WorldPosition)
	pSpring.d = 1
	pSpring.s = 20
	self.positionSpring = pSpring
	
	local nSpring = Spring.new(Vector3.yAxis)
	pSpring.d = 1
	pSpring.s = 20
	self.normalSpring = nSpring
	
	local th = arg.targetHover 
	
	if not th then
		th = Instance.new('Attachment')
		th.Name = '__targetHover'
		th.Visible = true
	end
	
	self.targetHover = th
	
	self:updateStep()
	
	return self
end

module.getNewStep = function(self: object)
	local down = Vector3.new(0,-50)
	local resultRaycast = workspace:Raycast(
		self.targetHover.WorldPosition, 
		down,
		self.rayParams
	)
	
	return resultRaycast and resultRaycast.Position or self.targetHover.WorldPosition - down,
		resultRaycast and resultRaycast.Normal or Vector3.yAxis
end

module.getBigL = function(self: object)
	local result = 0
	local lJs = self.legJoints
	
	for i = 2, #lJs do
		local last = lJs[i - 1]
		local current = lJs[i]
		
		result += (
				Vector3Utils.getAbsolutePosition(last) - 
				Vector3Utils.getAbsolutePosition(current)
			).Magnitude
	end
	
	return result
end

module.getSmallD = function(self: object)
	return (self.hip.WorldPosition - self.footTarget.WorldPosition).Magnitude
end

module.updateStep = function(self: object)
	local p, n = self:getNewStep()
	self.positionSpring.t = p
	self.normalSpring.t = n
end

module.update = function(self: object, dt: number)
	local d = self:getSmallD()
	
	self.positionSpring:update(dt)
	self.normalSpring:update(dt)

	if d > self.bigL and self.shouldStep then
		self:updateStep()
	end
	
	--s:update(dt)
	self.footTarget.WorldPosition = self.positionSpring.p
	self.footTarget.WorldSecondaryAxis = self.normalSpring.p
end

module.__index = module;
module.className = '@CHL/ProceduralLeg'

return module
