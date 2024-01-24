--// TYPES
local Objects = script.Parent

type __object = {
	humanoid: Humanoid;
	isWalking: (self: __object) -> boolean;
}
export type object = __object

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise
module.__index = module

function module.new(h: Humanoid)
	local self: __object = disguise(setmetatable({}, module))
	self.humanoid = h
	return self
end

module.isWalking = function(self: __object)
	local h = self.humanoid
	return h.MoveDirection.Magnitude > .5 and 
		h:GetState()==Enum.HumanoidStateType.Running and
		h.FloorMaterial ~= Enum.Material.Air
end

return module
