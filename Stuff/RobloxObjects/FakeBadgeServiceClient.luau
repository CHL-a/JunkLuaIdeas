local RemoteFolder = require('./@CHL>RemoteFolder')
local StarterGui = require('./@CHL>StarterGui')

local module = {}
local player = game:GetService('Players').LocalPlayer

RemoteFolder.static_get_event('award_badge').OnClientEvent:Connect(function(badge_name)
	local publisher = script:GetAttribute('__publisher') or 'FakeDataStore2'

	StarterGui.core.notification.send({
		Title = 'Badge Awarded';
		Text = `{player.Name} won {publisher}'s "{badge_name}" award`;
		Duration = 10;
		Icon = 'rbxassetid://7577357898'
	})
end)

if not player.Character then
	player.CharacterAdded:Once(function(character: Model)
		RemoteFolder.static_get_event('award_badge'):FireServer()
		
	end)
else
	RemoteFolder.static_get_event('award_badge'):FireServer()
end


return module
