local module = {}

--######################################################################################################################################################
--######################################################################################################################################################
--######################################################################################################################################################

-- subject to have its own constraint library

--######################################################################################################################################################
--######################################################################################################################################################
--######################################################################################################################################################

local Class = require('./Class')
local Object = require('./Object')
local Catenary = require('./@CHL>Catenary')

export type simple = {
	catenary: Catenary.curve_3d;
	attachment_0: Attachment;
	attachment_1: Attachment;
	length: number;
	parts: {Part};
	parent: Instance;
	
	segments: number;
	width: number;
	color: Color3;
	material: Enum.Material;
	transparency: number;
	can_collide: boolean;
	
	set_segments: (self: simple, segments: number) -> ();
	set_width: (self: simple, width: number) -> ();
	set_length: (self: simple, length: number) -> ();
	set_color: (self: simple, color3: Color3) -> ();
	set_material: (self: simple, material: Enum.Material) -> ();
	set_transparency: (self: simple, transparency: number) -> ();
	set_can_collide: (self: simple, can_collide: boolean) -> ();
	
	update: (self: simple) -> ();
}

disguise = require('./LuaUTypes').disguise
simple = {}

function simple.new(attachment_0: Attachment, attachment_1: Attachment, segments: number?): simple
	local self: simple = Object.simple.new(simple)
	
	self.segments = segments or 10
	self.length = (attachment_0.WorldPosition - attachment_1.WorldPosition).Magnitude + 1
	self.catenary = Catenary.dimension_3.new(attachment_0.WorldPosition, attachment_1.WorldPosition, self.length)
	self.attachment_0 = attachment_0
	self.attachment_1 = attachment_1
	self.parts = {}
	self.width = .1
	self.color = BrickColor.new("Medium stone grey").Color
	self.material = Enum.Material.Plastic
	self.transparency = 0
	self.can_collide = false
	
	self:set_length(self.length)
	
	return self
end

function simple.set_length(self: simple, length: number)
	self.length = length
	self.catenary:set_length(length)
	self:update()
end

function simple.set_segments(self: simple, segments: number)
	for i = segments, self.segments do
		local part = self.parts[i]
		
		if not part then continue end
		
		part:Destroy()
	end
	
	self.segments = segments
end

function simple.set_width(self: simple, width: number)
	self.width = width
	
	for _, part in self.parts do
		part.Size = Vector3.new(part.Size.X, width, width)
	end
end

function factory_set_part_property(property: string)
	return function(self: simple, value: any)
		self[property:lower()] = value
		
		for _, part in self.parts do
			part[property] = value
		end
	end
end

simple.set_color = factory_set_part_property('Color')
simple.set_material = factory_set_part_property('Material')
simple.set_transparency = factory_set_part_property('Transparency')
simple.set_can_collide = factory_set_part_property('CanCollide')

function simple.update(self: simple)
	local attachment_0 = self.attachment_0
	local attachment_1 = self.attachment_1
	local catenary = self.catenary
	
	local p_0 = attachment_0.WorldPosition
	local p_1 = attachment_1.WorldPosition
	
	local last_position = p_0
	
	catenary:set_point_0(p_0)
	catenary:set_point_1(p_1)
	
	for i = 1, self.segments do
		local increment = i / self.segments
		local part: Part = self.parts[i]
		
		if not disguise(part) then
			local parent = self.parent or attachment_0.Parent
			part = Instance.new('Part')
			
			part.Anchored = true
			part.CanCollide = self.can_collide
			part.Parent = parent
			part.Transparency = self.transparency
			part.Material = self.material
			part.Color = self.color
			part.Shape = Enum.PartType.Cylinder
			
			self.parts[i] = part
		end
		
		local position = self.catenary:point_at(increment)
		
		part.CFrame = CFrame.lookAt(last_position:Lerp(position, .5), last_position) * CFrame.Angles(0, math.pi/2, 0)
		part.Size = Vector3.new((position - last_position).Magnitude, self.width, self.width)
		
		last_position = position
	end
end

Class.make_proper_class(simple, '@CHL>Rope')

module.simple = simple

--######################################################################################################################################################
--######################################################################################################################################################
--######################################################################################################################################################

return module
