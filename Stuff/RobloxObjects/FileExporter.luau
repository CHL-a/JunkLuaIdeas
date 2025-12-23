--[[
	Module responsible for exporting a file, ascii files only
]]

local TableToString = require('./@CHL>TableToString')

local module = {}

disguise = require('./LuaUTypes').disguise
Selection = game:GetService('Selection')
ServerStorage = game:GetService('ServerStorage')

function module.export_string(content: string): any?
	local file_export = ServerStorage:FindFirstChild('__package') or Instance.new('Script')
	file_export.Name = '__package'
	file_export.Source = content
	file_export.Parent = ServerStorage
	
	local last_selection = Selection:Get()
	Selection:Set{file_export}
	assert(
		disguise(module).prompt, 
		'module function not set. Set module.prompt to a function which does the same as \z
		(plugin:PromptSaveSelection). It is not set due to some random limitation'
	)()
	
	plugin:PromptSaveSelectionAsync('lua')
	return Selection:Set(last_selection)
end

return module
