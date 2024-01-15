--// TYPES
type __object = {
	folder: Folder;
	getSound: (self: __object, name: string) -> Sound;
}
export type object = __object

--// MAIN
local module = {}
local Objects = script.Parent
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise

module.__index = module

function module.new(folder: Folder): __object
	local self: __object = disguise(setmetatable({}, module))
	
	self.folder = folder
	
	return self
end

module.getSound = function(self: __object, name: string)
	local s = self.folder:FindFirstChild(name)
	
	return assert(s, `Missing a sound: {name}`)
end

return module
