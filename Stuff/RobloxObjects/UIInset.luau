-- used to get ui insets
-- the standard is defined by Enum.CoreGuiInsets since absolute position defines 0,0 as such.

local InstanceUtils = require('./@CHL>InstanceUtils')
local module = {}

function get_screengui(): ScreenGui
	return InstanceUtils.getOrCreate(script, 'ScreenGuiCheck', 'ScreenGui')
end

function module.get_inset(enum: Enum.ScreenInsets): Vector2
	local player = game:GetService('Players').LocalPlayer
	local player_gui = player.PlayerGui
	local gui = get_screengui()
	
	gui.ScreenInsets = enum
	gui.Parent = player_gui
	
	local result = gui.AbsolutePosition
	
	gui.Parent = script
	
	return result
end

return module
