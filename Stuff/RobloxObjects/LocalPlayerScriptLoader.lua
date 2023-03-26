type __object = {
	oldParent: Instance;
	localScript: LocalScript;
	currentOwners: {LocalScript};
	
	undo: (self: __object) -> nil;
}

export type object = __object;

--#########################################
--#########################################
--#########################################

local LocalPlayerScriptLoader = {}
LocalPlayerScriptLoader.__index = LocalPlayerScriptLoader

function LocalPlayerScriptLoader.new(LocalScript)
	-- pre
	assert(typeof(LocalScript) == 'Instance' and LocalScript:IsA('LocalScript'))
	
	-- main
	local object = setmetatable({}, LocalPlayerScriptLoader)
	
	object.oldParent = LocalScript.Parent
	object.localScript = LocalScript
	object.currentOwners = {}
	
	for _, v in next, game:GetService('Players'):GetPlayers() do
		local playerGui = v:FindFirstChildWhichIsA('PlayerGui')
		
		if playerGui then
			local sG = Instance.new('ScreenGui')
			sG.ResetOnSpawn = false
			
			local clone = LocalScript:Clone()
			
			table.insert(object.currentOwners, clone)
			clone.Parent = sG
			sG.Parent = playerGui
		end
	end
	
	LocalScript.Parent = game.StarterPlayer.StarterPlayerScripts
	
	return object
end

function LocalPlayerScriptLoader.undo(self: __object)
	self.localScript.Parent = self.oldParent

	for _, v in next, self.currentOwners do
		if typeof(v) == 'Instance' and v.Parent then
			v.Parent:Destroy()
		end
	end
end

return LocalPlayerScriptLoader
