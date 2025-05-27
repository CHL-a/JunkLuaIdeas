--// TYPES
local Object = require('./Object')
local Class = require('./Class')

export type object = {
	container: Instance;
	getSound: (self: object, name: string) -> Sound;
	findSound: (self: object, name: string) -> Sound?
} & Object.object_inheritance

--// MAIN
local LuaUTypes = require('./LuaUTypes')

module = {}
disguise = LuaUTypes.disguise

function module.new(inst: Instance): object
	local self: object = Object.from.class(module)
		
	self.container = inst
	
	return self
end

function module.getSound(self: object, name: string)
	return assert(self:findSound(name), `Missing a sound: {name}`)
end

function module.findSound(self:object, name: string)
	return self.container:FindFirstChild(name)
end

Class.makeProperClass(module, '@CHL>SoundFolder')

return module
