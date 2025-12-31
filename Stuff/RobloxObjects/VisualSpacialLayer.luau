--[[
	TODO: Find a better name than space layer
	
	Object attempts to replicate a space and impose it as a vision onto player, works best if viewport is under a screengui that ignores gui inset
]]

local Class = require('./Class')
local Object = require('./Object')
local Insets = require('./@CHL>UIInsets')

export type object = {
	cropping_frame: Frame;
	viewport_frame: ViewportFrame;
	workspace_camera: Camera;
	
	get_viewport_camera: (self: object)->Camera;
	update: (self: object)->();
	
	-- attempts to retransform viewport such that it fills entire screen, including over gui inset
	--[[
		Only transforms position and size but does not accounts for absolute position and rotation
	]]
	retransform_viewport_frame: (self: object)->();
}

local module = {}

rad = math.rad
sin = math.sin
cos = math.cos

function module.new(cropping_frame: Frame, viewport_frame: ViewportFrame): object
	assert(viewport_frame.Parent == cropping_frame)
	
	local self: object = Object.simple.new(module)
	
	self.cropping_frame = cropping_frame
	self.viewport_frame = viewport_frame
	self.workspace_camera = workspace.CurrentCamera;
	
	return self
end

function module.get_viewport_camera(self: object)
	return self.viewport_frame.CurrentCamera
end

function module.dot(offset: Vector2, parent: GuiObject)
	local d = script.b:Clone()
	--offset = offset:Max(Vector2.zero)
	d.Position = UDim2.fromOffset(offset.X, offset.Y)
	d.Parent = parent
	return d
end

function module.line(from: Vector2, to: Vector2, parent: GuiObject)
	local d = script.b:Clone()
	local half = (to + from) / 2
	local diff = to - from
	local angle = math.atan2(diff.Y, diff.X)
	
	d.Size = UDim2.fromOffset(diff.Magnitude, d.Size.Y.Offset)
	d.Position = UDim2.fromOffset(half.X, half.Y)
	d.Rotation = math.deg(angle)
	d.Parent = parent
	return d
end

function module.absolute_top_left_position(abs_position: Vector2, abs_size: Vector2, abs_rotation: number)
	local half_size = abs_size / 2
	local angle_1 = math.atan(half_size.Y / half_size.X)
	local middle = abs_position + half_size
	local angle_2 = rad(180 + abs_rotation) + angle_1
	local unit = Vector2.new(cos(angle_2), sin(angle_2))
	
	local result = middle + unit * half_size.Magnitude
	
	return result
end

function module.retransform_viewport_frame(self: object)
	local cropping_frame: Frame = self.cropping_frame
	local viewport_frame: ViewportFrame = self.viewport_frame
	local screen_gui = viewport_frame:FindFirstAncestorWhichIsA('ScreenGui')
	local screen_size = screen_gui.AbsoluteSize
	
	-- size is always the same as the screen size
	viewport_frame.Size = UDim2.fromOffset(screen_size.X, screen_size.Y)
	
	local rotation = viewport_frame.AbsoluteRotation
	
	-- set position
	-- first, attempt to get a goal position by finding the a version of the top left position in 0 rotation space after applying rotation
	local none_inset = Insets.get_inset(screen_gui.ScreenInsets)
	local to = module.absolute_top_left_position(none_inset, screen_size, rotation)
	
	-- secondly, do the same logic for the source position as previous step
	local from = module.absolute_top_left_position(self.cropping_frame.AbsolutePosition, self.cropping_frame.AbsoluteSize, rotation)
	
	-- then transform 0 rotation space to rotation space
	-- based on the following equations:
	--[[
		f_i = from of ith axis
		t_i = to of ith axis
		d = delta = from - to
		d_i = displacement of ith axis
		
		u_1 = <x_1, y_1> = vector given by rotation
		u_2 = <x_2, y_2> = vector perpendicular to u_1, by 90 degrees clockwise

		(then attempt to presume u_i as magnitudes)
		
		i_j = ith axis component of u_j
		
		d_i = u_1 * i_1 + u_2 * i_2
		
		d_x = u_1 * x_1 + u_2 * x_2
		d_y = u_1 * y_1 + u_2 * y_2
		
		-- attempt to solve u_1 and u_2 by canceling u_1 first, solving for u_2 then back to u_1
		
		-- if y_1 ~= 0, then continue on with plan. If it is not, then u_1 is parallel to x axis, 
		-- and u_2 is parallel to y axis, in which case, that also means x_2 is 0
		
		a = x_1 / y_1
		(d_y = u_1 * y_1 + u_2 * y_2) * a
		a * d_y = u_1 * a * y_1 + u_2 * a * y_2
		
		-- attempt merge
		d_x - a * d_y = u_1 * x_1 + u_2 * x_2 - u_1 * a * y_1 - u_2 * a * y_2
		d_x - a * d_y = u_1 * x_1 + u_2 * x_2 - u_1 * (x_1 / y_1) * y_1 - u_2 * a * y_2
		d_x - a * d_y = u_1 * x_1 + u_2 * x_2 - u_1 * x_1 - u_2 * a * y_2
		d_x - a * d_y = u_2 * x_2 - u_2 * a * y_2
		d_x - a * d_y = u_2 * (x_2 - a * y_2)
		u_2 = (d_x - a * d_y) / (x_2 - a * y_2)
		
		-- back to u_1
		d_x = u_1 * x_1 + u_2 * x_2
		d_x - u_2 * x_2 = u_1 * x_1
		u_1 = (d_x - u_2 * x_2) / x_1
		
		-- for the case where y_1 == 0, then x_2 must be 0 since u_1 and u_2 are orthoganal
		-- therefore the equations can be rewritten like this:
		
		d_x = u_1 * x_1 + u_2 * x_2
		d_x = u_1 * x_1 + u_2 * 0
		d_x = u_1 * x_1
		
		d_y = u_1 * y_1 + u_2 * y_2
		d_y = u_1 * 0 + u_2 * y_2
		d_y = u_2 * y_2
	]]
	
	local orthoganal_rotation = rotation + 90

	local x_1 = cos(rad(rotation))
	local y_1 = sin(rad(rotation))
	local u_1;

	local x_2 = cos(rad(orthoganal_rotation))
	local y_2 = sin(rad(orthoganal_rotation))
	local u_2;	

	local delta = to - from
	local delta_x = delta.X
	local delta_y = delta.Y

	if rotation % 180 == 0 then
		-- denotes a specific case where u_1's vector is specifically parallel to x axis

		u_1 = delta_x / x_1
		u_2 = delta_y / y_2
	else
		-- as it turns out, this fun attempt to attempt to add cropping on spacial layers doesnt work
		-- due to a rotation clause on clipsdescendants
		local a = x_1 / y_1

		u_2 = (delta_x - a * delta_y) / (x_2 - y_2 * a)
		u_1 = (delta_x - u_2 * x_2) / x_1
	end
	
	viewport_frame.Position = UDim2.fromOffset(u_1, u_2)
	
	-- set rotation by offsetting it
	viewport_frame.Rotation -= rotation
end

function module.update(self: object)
	local viewport_camera: Camera = self:get_viewport_camera()
	viewport_camera.CFrame = self.workspace_camera.CFrame
end

Class.make_proper_class(module, 'SpaceLayer')

return module
