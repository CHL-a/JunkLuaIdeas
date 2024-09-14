local Objects = script.Parent
local Object = require(Objects.Object)

export type object = {
	from: Vector3;
	to: Vector3;
	space: WorldRoot;
	raycast_params: RaycastParams?;

	invoke: (self: object)->RaycastResult?;
} & Object.object_inheritance

local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new(
	from: Vector3, 
	to: Vector3,
	raycast: RaycastParams?,
	space: WorldRoot?): object
	local self: object = Object.from.class(module)
	self.from = from;
	self.to = to;
	self.space = space or workspace
	self.raycast_params = raycast

	return self
end

function module.invoke(self: object)
	local from = self.from
	return self.space:Raycast(from,self.to-from,self.raycast_params)
end

function module.destroy(self: object)
	self.raycast_params = nil
	self.space = disguise()
	self.__super:Destroy()
end

module.__index = module
module.className = '@CHL/Ray'

return module
