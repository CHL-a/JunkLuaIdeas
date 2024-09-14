local Objects = script.Parent
local Object = require(Objects.Object)
local CRay = require(Objects["@CHL/Ray"])
local Class = require(Objects.Class)

export type filter_heuristic = (RaycastResult) -> boolean;

export type object = {
	filter_heuristic: filter_heuristic?;
	
	heuristic_invoke: (self: object)->RaycastResult?;
} & Class.subclass<CRay.object>

local module = {}

function module.new(
	from: Vector3, 
	to: Vector3, 
	filter: filter_heuristic?,
	raycast: RaycastParams?,
	space: WorldRoot?): object
	local self: object = CRay.new(from, to, raycast, space):__inherit(module)
	self.filter_heuristic = filter
	
	return self
end

function module.heuristic_invoke(self: object)
	local result = self:invoke()
	if not result then return end
	
	while true do
		self.from = result.Position
		
		if self.filter_heuristic and not self.filter_heuristic(result) then
			result = self:invoke()
			continue
		end
		
		break;
	end
	
	return result
end

function module.destroy(self: object)
	self.filter_heuristic = nil
	self.__super:Destroy()
end

module.__index = module
module.className = '@CHL/HeuristicRay'

return module
