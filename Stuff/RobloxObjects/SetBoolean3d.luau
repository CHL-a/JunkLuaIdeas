local module = {}

local Vector3Utils = require('./@CHL>Vector3Utils')

get_closer_vector3 = Vector3Utils.get_closer_vector3

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

export type operand = {
	is_true: (self: operand, vector3: Vector3) -> boolean;
}

export type shape = {
	cframe: CFrame;
	size: Vector3;
	
	basic_side_check: (self: shape, local_axis: Enum.Axis, sign: number, position: Vector3) -> boolean;
} & operand

export type rectangular_prism = shape

local Object = require('./Object')
local Class = require('./Class')

shapes = {}
shapes.rectangular_prism = {}
shapes.rectangular_prism.from = {}

function shapes.rectangular_prism.new(cframe: CFrame, size: Vector3): rectangular_prism
	local self: rectangular_prism = Object.simple.new(shapes.rectangular_prism)
	
	self.cframe = cframe
	self.size = size
	
	return self
end

function shapes.rectangular_prism.basic_side_check(self: shape, local_axis: Enum.Axis, sign: number, arg: Vector3)
	local vector_name
	
	if local_axis == Enum.Axis.X then
		vector_name = 'RightVector'
	elseif local_axis == Enum.Axis.Y then
		vector_name = 'UpVector'
	elseif local_axis == Enum.Axis.Z then
		vector_name = 'LookVector'
	end
	
	local position = self.cframe.Position
	local vector_0 = self.cframe[vector_name] * self.size[local_axis.Name] * sign
	local vector_1 = position + vector_0
	
	local closest = get_closer_vector3(arg, position, vector_1)
	
	return closest == position
end

function shapes.rectangular_prism.is_true(self: rectangular_prism, vector3: Vector3): boolean
	local cframe = self.cframe
	local size = self.size
	local position = cframe.Position
	
	return self:basic_side_check(Enum.Axis.X, -1, vector3) and
		self:basic_side_check(Enum.Axis.X, 1, vector3) and
		self:basic_side_check(Enum.Axis.Y, -1, vector3) and
		self:basic_side_check(Enum.Axis.Y, 1, vector3) and
		self:basic_side_check(Enum.Axis.Z, -1, vector3) and
		self:basic_side_check(Enum.Axis.Z, 1, vector3)
end

function shapes.rectangular_prism.from.part(part: Part): rectangular_prism
	assert(part.Shape == Enum.PartType.Block)
	return shapes.rectangular_prism.new(part.CFrame, part.Size)
end

Class.make_proper_class(shapes.rectangular_prism, '@CHL>SetBoolean3D>Shapes>RectangularPrism')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

export type sphere = {
	cframe: CFrame;
	radius: number;
} & operand

shapes.sphere = {}
shapes.sphere.from = {}

function shapes.sphere.new(cframe: CFrame, radius: number): sphere
	local self: sphere = Object.simple.new(shapes.sphere)
	
	self.cframe = cframe
	self.radius = radius
	
	return self
end

function shapes.sphere.is_true(self: sphere, position: Vector3)
	return (position - self.cframe.Position).Magnitude <= self.radius
end

function shapes.sphere.from.part(part: Part): sphere
	assert(part.Shape == Enum.PartType.Ball)
	local size = part.Size
	return shapes.sphere.new(part.CFrame, math.min(size.X, size.Y, size.Z) / 2)
end

Class.make_proper_class(shapes.sphere, '@CHL>SetBoolean3D>Shapes>Sphere')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

export type triangular_prism = {
	cframe: CFrame;
	size: Vector3;
	
	basic_side_check: (self: shape, local_axis: Enum.Axis, sign: number, position: Vector3) -> boolean;
} & operand

shapes.triangular_prism = {}
shapes.triangular_prism.from = {}

function shapes.triangular_prism.new(cframe: CFrame, size: Vector3): triangular_prism
	local self: triangular_prism = Object.simple.new(shapes.triangular_prism)
	
	self.cframe = cframe
	self.size = size
	
	return self
end

function shapes.triangular_prism.is_true(self: triangular_prism, position: Vector3): boolean
	local basic_side_check = self:basic_side_check(Enum.Axis.X, 1, position) and 
		self:basic_side_check(Enum.Axis.X, -1, position) and 
		self:basic_side_check(Enum.Axis.Y, -1, position) and 
		self:basic_side_check(Enum.Axis.Z, -1, position)
	
	if not basic_side_check then 
		return false 
	end
	
	-- slant
	local cframe = self.cframe
	local size = self.size
	local inside_vector = -cframe.UpVector * size.Y - cframe.LookVector * size.Z
	local outside_vector = -inside_vector
	
	local closest = get_closer_vector3(position - self.cframe.Position, inside_vector, outside_vector)
	
	return closest == inside_vector
end

function shapes.triangular_prism.from.part(part: Part): triangular_prism
	assert(part.Shape == Enum.PartType.Wedge)
	local size = part.Size
	return shapes.triangular_prism.new(part.CFrame, size)
end

shapes.triangular_prism.basic_side_check = shapes.rectangular_prism.basic_side_check

Class.make_proper_class(shapes.triangular_prism, '@CHL>SetBoolean3D>Shapes>TriangularPrism')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- untested
export type corner_wedge = {
	cframe: CFrame;
	size: Vector3;
} & operand

shapes.corner_wedge = {}
shapes.corner_wedge.from = {}

function shapes.corner_wedge.new(cframe: CFrame, size: Vector3): corner_wedge
	local self: corner_wedge = Object.simple.new(shapes.corner_wedge)
	
	self.cframe = cframe
	self.size = size
	
	return self
end

function shapes.corner_wedge.is_true(self: corner_wedge, position: Vector3): boolean
	local basic_side_check = self:basic_side_check(Enum.Axis.X, 1, position) and 
		self:basic_side_check(Enum.Axis.Y, -1, position) and 
		self:basic_side_check(Enum.Axis.Z, -1, position)
	
	if not basic_side_check then return false end
	
	-- slant 1
	local cframe = self.cframe
	local size = self.size
	local inside_vector = -cframe.UpVector * size.Y - cframe.LookVector * size.Z
	local outside_vector = -inside_vector
	
	local closest = get_closer_vector3(position - self.cframe.Position, inside_vector, outside_vector)
	
	if closest == outside_vector then
		return false
	end
	
	-- slant 2
	inside_vector = -cframe.UpVector * size.Y + cframe.RightVector * size.X
	outside_vector = -inside_vector
	
	closest = get_closer_vector3(position - self.cframe.Position, inside_vector, outside_vector)
	
	if closest == outside_vector then
		return false
	end
	
	return true
end

shapes.corner_wedge.basic_side_check = shapes.rectangular_prism.basic_side_check

Class.make_proper_class(shapes.corner_wedge, '@CHL>SetBoolean3D>Shapes>CornerWedge')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

export type positive_union = {
	collection: {operand},
} & operand

-- set boolean operations, starting with group/union
set_operations = {}
set_operations.positive_union = {}

function set_operations.positive_union.new(operands: {operand}): positive_union
	local self: positive_union = Object.simple.new(set_operations.positive_union)
	
	self.collection = operands
	
	return self
end

function set_operations.positive_union.is_true(self: positive_union, position: Vector3): boolean
	for _, operand in self.collection do
		if operand:is_true(position) then
			return true
		end
	end
	return false
end

Class.make_proper_class(set_operations.positive_union, '@CHL>SetBoolean3D>SetOperations>PositiveUnion')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

export type negation = {
	operand: operand
} & operand

set_operations.negation = {}

function set_operations.negation.new(operand: operand): negation
	local self: negation = Object.simple.new(set_operations.negation)
	
	self.operand = operand
	
	return self
end

function set_operations.negation.is_true(self: negation, position: Vector3): boolean
	return not self.operand:is_true(position)
end

Class.make_proper_class(set_operations.negation, '@CHL>SetBoolean3D>SetOperations>Negation')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

export type intersection = {
	operands: {operand}
} & operand

set_operations.intersection = {}

function set_operations.intersection.new(operands: {operand}): intersection
	local self: intersection = Object.simple.new(set_operations.intersection)
	
	self.operands = operands
	
	return self
end

function set_operations.intersection.is_true(self: intersection, position: Vector3): boolean
	for _, operand in self.operands do
		if not operand:is_true(position) then
			return false
		end
	end
	
	return true
end

Class.make_proper_class(set_operations.intersection, '@CHL>SetBoolean3D>SetOperations>Intersection')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

module.set_operations = set_operations
module.shapes = shapes

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

return module
