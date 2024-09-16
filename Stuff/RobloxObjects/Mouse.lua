--[[
	Wrapper of mouse because it has interesting behavior that I don't know where it originates
	https://create.roblox.com/docs/reference/engine/classes/Mouse#Hit
--]]

local Objects = script.Parent
local Object = require(Objects.Object)
local HRay = require(Objects["@CHL/HeuristicRay"])

type filter_heuristic = HRay.filter_heuristic

export type object = {
	mouse: Mouse;
	camera: Camera;
	range: number;
	
	get_hit_raycast: (self: object, filter: filter_heuristic?, 
		params: RaycastParams?)->RaycastResult?;
	get_hit:
		(self: object, filter: filter_heuristic?, params: RaycastParams?)->CFrame;
	get_origin: (self: object, filter: filter_heuristic?, params: RaycastParams?)->CFrame;
	get_target: (self: object, filter: filter_heuristic?, params: RaycastParams?)->
		(BasePart | Terrain)?;
} & Object.object_inheritance

local module = {}

function module.new(mouse: Mouse, camera: Camera?): object
	local self: object = Object.from.class(module)
	
	self.mouse = mouse
	self.camera = camera or workspace.CurrentCamera
	self.range = 1E3
	return self
end

function module.get_hit_raycast(
	self: object, 
	filter: filter_heuristic?, 
	params: RaycastParams?)
	local h = HRay.new(
		self.camera.CFrame.Position, 
		self.mouse.Hit.Position,
		filter,
		params
	)
	
	h.to = h.from + h:get_displacement().Unit * self.range
	
	return h:heuristic_invoke()
end

function module.get_hit(self: object, f: filter_heuristic?, p: RaycastParams?)
	local r = self:get_hit_raycast(f, p)
	return r and CFrame.new(r.Position) * self:get_origin(f, p).Rotation or self.mouse.Hit
end

function module.get_origin(self: object, f: filter_heuristic?, p: RaycastParams?)
	local rR = self:get_hit_raycast(f, p)
	return rR and CFrame.lookAt(self.camera.CFrame.Position, rR.Position)
		or self.mouse.Origin
end

function module.get_target(self: object, f: filter_heuristic?, p: RaycastParams?)
	local r = self:get_hit_raycast(f, p)
	return r and r.Instance or nil
end

module.className = '@CHL/Mouse'
module.__index = module

return module
