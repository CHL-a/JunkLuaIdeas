--[[
	Serves as an extention to Nevermore/Maid, with some extra methods and such
	
	Original:
	https://devforum.roblox.com/t/how-to-use-a-maid-class-on-roblox-to-manage-state/340061
]]
--// TYPES
local Objects = script.Parent
local Class = require(Objects.Class)
local Destructable = require(Objects["@CHL/Destructable"])
local Maid = require(Objects["@Nevermore/Maid"])
local TableUtils = require(Objects["@CHL/TableUtils"])

export type __task = (() -> ()) | RBXScriptConnection | Destructable.object;

export type object = {
	accessTasks: boolean;
	
	assignTask: (self: object, i: string, __task) -> nil;
	destroy: (self: object) -> ();
	
	-- super
	GiveTask: (self: object, __task) -> ();
	GivePromise: <A>(self: object, A) -> A;
	DoCleaning: (self: object) -> ();
	Destroy: (self: object) -> ();
} & Destructable.object

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise

module.__index = module

module.__newindex = function(self: object, i: string, v: any)
	if not self.accessTasks then
		rawset(self, i, v)
	else
		Maid.__newindex(self, i, v)
	end
end

function module.new(): object
	local self: object = Class.inherit(Maid.new(), module)
	
	return self
end

TableUtils.imprint(module, Destructable)

module.assignTask = function(self: object, i: string, t: __task)
	local old = self.accessTasks
	self.accessTasks = true
	
	disguise(self)[i] = t
	
	self.accessTasks = old
end

module.destroy = function(self: object)
	self.isDestroyed = true
	self:DoCleaning()
end

module.Destroy = module.destroy

return module
