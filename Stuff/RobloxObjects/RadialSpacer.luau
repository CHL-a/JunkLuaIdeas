--[[
	Adds a radial collision spacer onto your character to keep them away from walls of a certain radius
]]

local module = {}

simple = {}

function simple.get_1()
	local result: Part = script:FindFirstChild('simple_1')
	
	if result then
		return result
	end
	
	local result_1 = Instance.new('Part')
	
	result_1.Size = Vector3.new(1,3,3)
	result_1.Shape = Enum.PartType.Cylinder
	result_1.Transparency = simple.is_translucent and .5 or 1
	result_1.Massless = true
	result_1.CanTouch = false
	result_1.CanQuery = false
	result_1.AudioCanCollide = false
	
	local weld = Instance.new('Weld')
	weld.Part1 = result_1
	weld.C0 = CFrame.Angles(0, 0, math.pi / 2)
	weld.Parent = result_1
	
	return result_1
end

function simple.func_1(hrp: BasePart)
	local result = simple.get_1()
	
	local weld = result:FindFirstChildWhichIsA('Weld')
	weld.Part0 = hrp
	
	result.Parent = hrp.Parent
	
	return result
end

simple.is_translucent = true

module.simple = simple

--#############################################################################################################################################################################################################
--#############################################################################################################################################################################################################
--#############################################################################################################################################################################################################

export type object = {
	parent: BasePart,
	part: Part;
	
	toggle_collision: (self: object, explicit_value: boolean?) -> ();
}

local Class = require('./Class')
local Object = require('./Object')

object = {}

function object.new(hrp: BasePart)
	local self: object = Object.simple.new(object)
	
	self.part = simple.func_1(hrp)
	self.parent = hrp
	
	return self
end

function object.toggle_collision(self: object, explicit_value: boolean?)
	if explicit_value == nil then
		explicit_value = not self.part.CanCollide
	end
	
	self.part.CanCollide = explicit_value
end

Class.make_proper_class(object, '@CHL>RadialSpacer')

module.object = object

--#############################################################################################################################################################################################################
--#############################################################################################################################################################################################################
--#############################################################################################################################################################################################################

return module
