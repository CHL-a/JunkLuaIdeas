local Objects = game:GetService('ReplicatedStorage').Objects

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type object = {
	oldParent: Instance;
	localScript: LocalScript;
	currentOwners: {LocalScript};
	
	undo: (self: object) -> ();
} & Object.object_inheritance

--##################################################################################
--##################################################################################
--##################################################################################

local LocalPlayerScriptLoader = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise

function LocalPlayerScriptLoader.new(LocalScript: LocalScript): object
	-- main
	local self: object = Object.from.class(LocalPlayerScriptLoader)
	
	self.oldParent = disguise(LocalScript.Parent)
	self.localScript = LocalScript
	self.currentOwners = {}
	
	for _, v in next, game:GetService('Players'):GetPlayers() do
		local playerGui = v:FindFirstChildWhichIsA('PlayerGui')
		
		if playerGui then
			local sG = Instance.new('ScreenGui')
			sG.ResetOnSpawn = false
			
			local clone = LocalScript:Clone()
			
			table.insert(self.currentOwners, clone)
			clone.Parent = sG
			sG.Parent = playerGui
		end
	end
	
	LocalScript.Parent = game:GetService('StarterPlayer').StarterPlayerScripts
	
	return self
end

function LocalPlayerScriptLoader.undo(self: object)
	self.localScript.Parent = self.oldParent

	for _, v in next, self.currentOwners do
		if typeof(v) == 'Instance' and v.Parent then
			v.Parent:Destroy()
		end
	end
end

Class.makeProperClass(LocalPlayerScriptLoader, '@CHL>LocalPlayerScriptLoader')

return LocalPlayerScriptLoader
