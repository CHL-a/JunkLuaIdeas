-- SPEC
export type object = {
	position: Vector3;
	direction: Vector3;
	positionPart: Part;
	directionPart: Part;

	setPosition: (self: object, Vector3) -> object;
	setDirection: (self: object, Vector3) -> object;
}

-- CLASS
local VectorDisplay = {}
VectorDisplay.__index = VectorDisplay

function VectorDisplay.new(position: Vector3, direction: Vector3?)
	local result = setmetatable({}, VectorDisplay)
	local result: object = result;
	
	result.position = position;
	result.direction = direction or Vector3.zero;
	result.positionPart = Instance.new('Part')
	result.directionPart = Instance.new('Part')
	
	local a = result.positionPart
	a.Transparency = .5
	a.Size = Vector3.new(1,1,1)
	a.Shape = 'Ball'
	a.Color = Color3.new(1)
	a.Anchored = true
	a.CanCollide = false
	a.Parent = workspace
	
	local b = result.directionPart
	b.Transparency = .5
	b.Size = Vector3.new(1,.5,.5)
	b.Shape = Enum.PartType.Cylinder
	b.Anchored = true
	b.CanCollide = false
	b.Color = Color3.new(1)
	b.Parent = workspace
	
	result:setPosition(result.position)
	result:setDirection(result.direction)
	
	return result
end

VectorDisplay.setPosition = function(self: object, v: Vector3)
	self.position = v
	self.positionPart.Position = v
	local a = self.directionPart
	a.CFrame = CFrame.lookAt(v, v + self.direction)
		* CFrame.Angles(0,-math.pi/2,0)
		* CFrame.new(a.Size.X / -2,0,0)
end

VectorDisplay.setDirection = function(self: object, v: Vector3)
	self.direction = v
	local a = self.directionPart

	a.Size = Vector3.new(v.Magnitude, .5, .5)
	a.CFrame = CFrame.lookAt(self.position, v + self.position)
		* CFrame.Angles(0,-math.pi/2,0) 
		* CFrame.new(a.Size.X / -2,0,0)
end

return VectorDisplay
