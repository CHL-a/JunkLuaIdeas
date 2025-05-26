--// TYPE
local Object = require('./Object')
local Class = require('./Class')

export type EndEffector = BasePart | Motor6D | Attachment | Bone

export type object =  {
	collection: {IKControl};
	
	enable: (self: object, isEnabled: boolean) -> ();
	add: (self: object, ...IKControl) -> ();
	getIKControlFromEnd: (self: object, EndEffector) -> IKControl?;
} & Object.object_inheritance

--// MAIN
local module = {}
local TableUtils = require('./@CHL>TableUtils')

disguise = require('./LuaUTypes').disguise

function module.new(...: IKControl): object
	local self: object = Object.new():__inherit(module)
	
	self.collection = {...}
	
	return self;
end

function module.enable(self: object, isEnabled: boolean)
	for _, v in self.collection do
		v.Enabled = isEnabled
	end
end

function module.add(self: object, ...: IKControl)
	TableUtils.push(self.collection, ...)
end

function module.getIKControlFromEnd(self: object, e: EndEffector)
	for _, v in next, self.collection do
		if v.EndEffector == e then
			return v;
		end
	end
end

Class.makeProperClass(module, '@CHL>IKCollection')

return module
