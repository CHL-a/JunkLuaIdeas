--// TYPES
local Objects = script.Parent

type __object = {
	parent: BasePart;
	vectorForce: VectorForce;
	
	setForce: (self: __object, Vector3) -> nil;
}
export type object = __object

--// MAIN

local module = {}
local LuaUTypes = require(Objects.LuaUTypes)
local Dash = require(Objects["@CHL/DashSingular"])

disguise = LuaUTypes.disguise
module.__index = module

function module.new(parent: BasePart, at: Attachment): __object
	local self: __object = disguise(setmetatable({}, module))
	
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

module.setForce = function(self:__object, v3: Vector3)
	self.vectorForce.Force = v3 - 
		Vector3.yAxis * module.massSum(self.parent) * workspace.Gravity
end


return module
