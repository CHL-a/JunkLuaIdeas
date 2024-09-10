--[[
	Note: This serves as an extension to the camera with an addition:
	
	 * AttachOnPart: Camera Attaches itself to part without influence of player controls
]]

-- TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)
local RuntimeUpdater = require(Objects.RuntimeUpdater)
local CNum = require(Objects["@CHL/Enum"])
local Spring = require(Objects["@CHL/Spring"])

--#######################################################################################
--#######################################################################################
--#######################################################################################

type enum_item<U> = CNum.enum_item<U>

local FOVUpdateMode: CNum.enum<
	'Default' | 'Spring',
	{
		Default: enum_item<'Default'>;
		Spring: enum_item<'Spring'>;
	}
	> = CNum.new{'Default', 'Spring'}

export type FOVUpdateMode = typeof(FOVUpdateMode.union)

--#######################################################################################
--#######################################################################################
--#######################################################################################

export type mode = Enum.CameraType 
	| 'AttachOnPart'

export type object = {
	camera: Camera;
	mode: mode;
	fov_update_mode: enum_item<FOVUpdateMode>;
	fov_spring: Spring.object<number>;
	
	changeMode: (self: object, m: mode) -> ();
	changeFOVUpdateMode: (self: object, m: FOVUpdateMode)->();
} & Object.object_inheritance
  & RuntimeUpdater.updatable

-- MAIN
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new(c: Camera): object
	local self: object = Object.from.class(module)
	
	self.camera = c;
	self.mode = c.CameraType
	self.fov_update_mode = FOVUpdateMode.enum_items.Default
	self.canUpdate = true
	
	return self
end

function module.changeFOVUpdateMode(self: object, m: FOVUpdateMode | enum_item<FOVUpdateMode>)
	if type(m) == 'string' then
		m = FOVUpdateMode.enum_items[m]
	end
	
	if self.fov_update_mode == m then return; end
	
	self.fov_update_mode = disguise(m)
	self.fov_spring.t = self.camera.FieldOfView
	self.fov_spring.p = self.camera.FieldOfView
end

function module.changeMode(self: object, m: mode)
	local old = self.mode
	
	if old == m then return end
	
	self.mode = m
	
	if m == 'AttachOnPart' then
		self.camera.CameraType = Enum.CameraType.Scriptable
		return
	end
	
	self.camera.CameraType = m
end

function module.update(self: object, dt: number)
	if self.mode == 'AttachOnPart' then
		local subject = self.camera.CameraSubject
		
		if (subject and subject:IsA('BasePart')) then 
			self.camera.CFrame = subject.CFrame
		end
	end
	
	if self.fov_update_mode == FOVUpdateMode.enum_items.Spring then
		self.fov_spring:update(dt)
		self.camera.FieldOfView = self.fov_spring.p
	end
end

module.enums = {
	FOVUpdateMode = FOVUpdateMode;
}
module.__index = module
module.className = '@CHL/Camera'

return module
