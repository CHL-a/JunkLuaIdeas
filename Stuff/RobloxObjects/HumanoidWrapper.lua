--// TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object = {
	humanoid: Humanoid;
	isWalking: (self: object) -> boolean;
} & Class.subclass<Object.object>

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise

function module.new(h: Humanoid)
	local self: object = Object.from.rawStruct({
		humanoid = h;
	}):__inherit(module) -- disguise(setmetatable({}, module))
	
	return self
end

module.isWalking = function(self: object)
	local h = self.humanoid
	
	return h.MoveDirection.Magnitude > .5 and 
		h:GetState()==Enum.HumanoidStateType.Running and
		h.FloorMaterial ~= Enum.Material.Air
end

module.__index = module
module.className = '@CHL/HumanoidWrapper'

return module
