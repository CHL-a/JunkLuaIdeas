-- SPEC
export type object = {
	localScript: LocalScript;
	oldParent: Instance;
	currentOwners: {Player};

	undo: (self: object) -> nil;
	giveLocalScript: (self: object, Player) -> nil
}

-- CLASS
local LocalPlayerScriptLoader = {}
LocalPlayerScriptLoader.__index = LocalPlayerScriptLoader

function LocalPlayerScriptLoader.new(lS: LocalScript)
	-- pre
	assert(typeof(ls) == 'Instance' and lS:IsA('LocalScript'))

	-- main
	local result = setmetatable({}, LocalPlayerScriptLoader)
	local result: object = result;
	
	result.oldParent = assert(lS.Parent)
	result.localScript = lS
	result.currentOwners = {}

	for _, v in next, game:GetService('Players'):GetPlayers() do
		result:giveLocalScript(v)
	end

	lS.Parent = game.StarterPlayer.StarterPlayerScripts

	return result
end

LocalPlayerScriptLoader.undo = function(self: object)
	self.localScript.Parent = self.oldParent

	for _, v in next, self.currentOwners do
		if typeof(v) == 'Instance' and v.Parent then
			v:Destroy()
		end
	end
end

LocalPlayerScriptLoader.giveLocalScript = function(self: object, p: Player)
	-- pre
	local playerGui = p:FindFirstChildWhichIsA('PlayerGui')
	if not playerGui then return end
	
	-- main
	local clone = self.localScript:Clone()

	clone.Parent = playerGui
	table.insert(self.currentOwners, clone)
end

return LocalPlayerScriptLoader
