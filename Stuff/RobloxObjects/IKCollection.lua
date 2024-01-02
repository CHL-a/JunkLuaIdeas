--// TYPE
type __endEffector = BasePart | Motor6D | Attachment | Bone
export type EndEffector = __endEffector

type __object = {
	collection: {IKControl};
	
	enable: (self: __object, isEnabled: boolean) -> nil;
	add: (self:__object, ...IKControl) -> nil;
	getIKControlFromEnd: (self: __object, __endEffector) -> IKControl?;
}
export type object = __object

--// MAIN
local module = {}
local disguise = require(script.Parent.LuaUTypes).disguise
local TableUtils = require(script.Parent['@CHL/TableUtils'])

module.__index = module

function module.new(...: IKControl)
	local self: __object = disguise(setmetatable({}, module))
	
	self.collection = {...}
	
	return self;
end

module.enable = function(self: __object, isEnabled: boolean)
	for _, v in next, self.collection do
		v.Enabled = isEnabled
	end
end

module.add = function(self: __object, ...: IKControl)
	TableUtils.push(self.collection, ...)
end

module.getIKControlFromEnd = function(self: __object, e: __endEffector)
	for _, v in next, self.collection do
		if v.EndEffector == e then
			return v;
		end
	end
end

return module
