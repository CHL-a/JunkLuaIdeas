export type result = 'game' | 'plugin' | 'unknown'

disguise = require(script.Parent.LuaUTypes).disguise

local success = pcall(function()script.RobloxLocked = script.RobloxLocked end)
local context : result = if success then 'plugin' else 'game'

return context
