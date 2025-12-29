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

function module.retransform_viewport_frame(self: object)
	local cropping_frame: Frame = self.cropping_frame
	local viewport_frame: ViewportFrame = self.viewport_frame
	local ScreenGui = viewport_frame:FindFirstAncestorWhichIsA('ScreenGui')
	local size = ScreenGui.AbsoluteSize
	
	-- size is always the same as the screen size
	viewport_frame.Size = UDim2.fromOffset(size.X, size.Y)
	
	if 1>0 then
		local from = cropping_frame.AbsolutePosition
		local to = Insets.get_inset(Enum.ScreenInsets.None)
		viewport_frame.Position = UDim2.fromOffset(
			-from.X + to.X,
			-from.Y + to.Y
		)
		
		return
	end
	
	
	-- set rotation by offsetting it
	local rotation = viewport_frame.AbsoluteRotation
	viewport_frame.Rotation -= rotation
	
	-- set position
	-- first establish visible from position because absolute position assumes 0 rotation
	-- attempt to modify by finding the middle then adjusting based on rotation
	local from = cropping_frame.AbsolutePosition
	local middle = from + cropping_frame.AbsoluteSize / 2
	local from_middle_displacement = middle - from
	local middle_length = from_middle_displacement.Magnitude
	local theta_1 = math.tan(from_middle_displacement.Y / from_middle_displacement.X)
	local theta_2 = rad(180 + rotation) + theta_1
	local unit = Vector2.new(cos(theta_2), sin(theta_2))
	
	from = middle + unit * middle_length

	-- use visual from point and to position to make a displacement
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
	local to = Insets.get_inset(Enum.ScreenInsets.None)
	
	local orthoganal_rotation = rotation + 90
	
	local x_1 = cos(rad(rotation))
	local y_1 = sin(rad(rotation))
	local u_2;	
	
	local x_2 = cos(rad(orthoganal_rotation))
	local y_2 = sin(rad(orthoganal_rotation))
	local u_1;

	local delta_x = to.X - from.X
	local delta_y = to.Y - from.Y
	
	print(math.round(y_1 * 1000) / 1000 )
	
	if math.round(y_1 * 1000) / 1000 == 0 then
		-- denotes a specific case where u_1's vector is specifically parallel to x axis
		
		u_1 = delta_x / x_1
		u_2 = delta_y / y_2
	else
		local a = x_1 / y_1
		
		u_2 = (delta_x - a * delta_y) / (x_2 - y_2 * a)
		u_1 = (delta_x - u_2 * x_2) / x_1
	end
	
	viewport_frame.Position = UDim2.fromOffset(u_1, u_2)
end

function module.update(self: object)
	local viewport_camera: Camera = self:get_viewport_camera()
	viewport_camera.CFrame = self.workspace_camera.CFrame
end

Class.make_proper_class(module, 'SpaceLayer')

return module
