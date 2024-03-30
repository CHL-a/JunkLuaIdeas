--// TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object = {
	container: Instance;
	getSound: (self: object, name: string) -> Sound;
	findSound: (self: object, name: string) -> Sound?
} & Class.subclass<Object.object>

--// MAIN
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new(inst: Instance): object
	local self: object = Object.new():__inherit(module)
		
	self.container = inst
	
	return self
end

module.getSound = function(self: object, name: string)
	return assert(self:findSound(name), `Missing a sound: {name}`)
end

module.findSound = function(self:object, name: string)
	return self.container:FindFirstChild(name)
end

module.__index = module
module.className = '@CHL/SoundFolder'

return module
