--// TYPES
local Objects = script.Parent
local Spring = require(Objects["@CHL/Spring"])
local RuntimeUpdater = require(Objects.RuntimeUpdater)

type __constructorArgs = {
	legJoints: {Attachment};
	foot: Attachment?;
	footTarget: Attachment;
	rayParams: RaycastParams;
	targetHover: Attachment?;
	iKControl: IKControl;
}
export type constructorArgs = __constructorArgs

type __object = {
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
	
	getBigL: (self: __object) -> number;
	getSmallD: (self: __object) -> number;
	getNewStep: (self: __object) -> (Vector3, Vector3);
	updateStep: (self: __object) -> nil;
} & RuntimeUpdater.updatable
export type object = __object

--// MAIN
local module = {}
local disguise = require(Objects.LuaUTypes).disguise
local Dash = require(Objects["@CHL/DashSingular"])
local Vector3Utils = require(Objects.Vector3Utils)

module.__index = module;

function module.new(arg: __constructorArgs): __object
	local self : __object = disguise(setmetatable({}, module))
	local joints = arg.legJoints
	
	self.hip = joints[1]
	self.foot = Dash.last(joints)
	self.legJoints = arg.legJoints
	self.bigL = self:getBigL()
	self.canUpdate = true
	self.footTarget = arg.footTarget
	self.rayParams = arg.rayParams
	self.shouldStep = true
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

module.getNewStep = function(self: __object)
	local down = Vector3.new(0,-50)
	local resultRaycast = workspace:Raycast(
		self.targetHover.WorldPosition, 
		down,
		self.rayParams
	)
	
	return resultRaycast and resultRaycast.Position or self.targetHover.WorldPosition - down,
		resultRaycast and resultRaycast.Normal or Vector3.yAxis
end

module.getBigL = function(self: __object)
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

module.getSmallD = function(self: __object)
	return (self.hip.WorldPosition - self.footTarget.WorldPosition).Magnitude
end

module.updateStep = function(self: __object)
	local p, n = self:getNewStep()
	self.positionSpring.t = p
	self.normalSpring.t = n
end

module.update = function(self: __object, dt: number)
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

return module
