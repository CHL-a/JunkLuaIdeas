--// TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object = {
	parent: BasePart;
	vectorForce: VectorForce;
	
	setForce: (self: object, Vector3) -> nil;
} & Class.subclass<Object.object>

--// MAIN

local module = {}
local Dash = require(Objects["@CHL/DashSingular"])

disguise = require(Objects.LuaUTypes).disguise

function module.new(parent: BasePart, at: Attachment): object
	local self: object = Object.new():__inherit(module)
	
	self.parent = parent
	
	local vF = Instance.new('VectorForce')
	vF.Attachment0 = at
	vF.RelativeTo = Enum.ActuatorRelativeTo.World
	vF.Name = 'Gravity'
	vF.Enabled = false
	vF.ApplyAtCenterOfMass = true
	vF.Parent = parent
	self.vectorForce = vF
	
	self:setForce(Vector3.zero)
	
	return self
end

function massSum(last, current)return last + current:GetMass()end

module.massSum = function(part: BasePart): number
	return Dash.reduce(part:GetConnectedParts(true), massSum, 0)
end

module.setForce = function(self: object, v3: Vector3)
	self.vectorForce.Force = v3 + 
		Vector3.yAxis * module.massSum(self.parent) * workspace.Gravity
end

module.__index = module
module.className = '@CHL/LocalGravity'

return module
