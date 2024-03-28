--[[
	Note: This serves as an extension to the camera with an addition:
	
	 * AttachOnPart: Camera Attaches itself to part without influence of player controls
]]

-- TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)
local RuntimeUpdater = require(Objects.RuntimeUpdater)

export type mode = Enum.CameraType 
	| 'AttachOnPart'

export type object = {
	camera: Camera;
	mode: mode;
	
	changeMode: (self: object, m: mode) -> ();
} & Class.subclass<Object.object>
  & RuntimeUpdater.updatable

-- MAIN
local module = {}

function module.new(c: Camera): object
	local self: object = Object.new():__inherit(module)
	
	self.camera = c;
	self.mode = c.CameraType
	
	return self
end

module.changeMode = function(self: object, m: mode)
	local old = self.mode
	
	if old == m then return end
	
	self.mode = m
	
	if m == 'AttachOnPart' then
		self.camera.CameraType = Enum.CameraType.Scriptable
		self.canUpdate = true
		return
	else
		self.canUpdate = false
	end
	
	self.camera.CameraType = m
end

module.update = function(self: object, dt: number)
	if self.mode == 'AttachOnPart' then
		local subject = self.camera.CameraSubject
		
		if not subject then return end
		if not subject:IsA('BasePart') then return end
		
		self.camera.CFrame = subject.CFrame
	end
end

module.__index = module
module.className = '@CHL/Camera'

return module
