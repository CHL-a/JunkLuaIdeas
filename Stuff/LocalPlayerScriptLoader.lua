local LocalPlayerScriptLoader = {}


function LocalPlayerScriptLoader.new(LocalScript)
	-- pre
	assert(typeof(LocalScript) == 'Instance' and LocalScript:IsA('LocalScript'))
	
	-- main
	local object = {}
	object.oldParent = LocalScript.Parent
	object.localScript = LocalScript
	object.currentOwners = {}
	
	function object:undo()
		object.localScript.Parent = object.oldParent
		
		for _, v in next, object.currentOwners do
			if typeof(v) == 'Instance' and v.Parent then
				v:Destroy()
			end
		end
	end
	
	for _, v in next, game:GetService('Players'):GetPlayers() do
		local playerGui = v:FindFirstChildWhichIsA('PlayerGui')
		
		if playerGui then
			local clone = LocalScript:Clone()
			
			clone.Parent = playerGui
			table.insert(object.currentOwners, clone)
		end
	end
	
	LocalScript.Parent = game.StarterPlayer.StarterPlayerScripts
	
	return object
end

return LocalPlayerScriptLoader
