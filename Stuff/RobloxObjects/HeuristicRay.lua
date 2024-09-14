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
	local result
	local dir = (self.to-self.from).Unit
	self.to = self.from + dir * 100
	
	while true do
		result = self:invoke()
		if not result then return end
		self.from = result.Position + dir * .01
		
		if self.filter_heuristic and not self.filter_heuristic(result) then
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
