--// TYPE
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type EndEffector = BasePart | Motor6D | Attachment | Bone

export type object =  {
	collection: {IKControl};
	
	enable: (self: object, isEnabled: boolean) -> nil;
	add: (self: object, ...IKControl) -> nil;
	getIKControlFromEnd: (self: object, EndEffector) -> IKControl?;
} & Class.subclass<Object.object>

--// MAIN
local module = {}
local TableUtils = require(Objects['@CHL/TableUtils'])

disguise = require(Objects.LuaUTypes).disguise

function module.new(...: IKControl): object
	local self: object = Object.new():__inherit(module)
	
	self.collection = {...}
	
	return self;
end

module.enable = function(self: object, isEnabled: boolean)
	for _, v in next, self.collection do
		v.Enabled = isEnabled
	end
end

module.add = function(self: object, ...: IKControl)
	TableUtils.push(self.collection, ...)
end

module.getIKControlFromEnd = function(self: object, e: EndEffector)
	for _, v in next, self.collection do
		if v.EndEffector == e then
			return v;
		end
	end
end

module.__index = module
module.className = '@CHL/IKCollection'

return module
