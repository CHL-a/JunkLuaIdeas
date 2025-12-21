--[[
	Pretty niche way of importing lua tables from files, which using a loadstring function
	
	Loadstring must be previously set within the module because the only way to use the default loadstring function is to enable it for all.
	
	Though the default loadstring is the easier approach, it's best to use a version of loadstring used within plugin space.
]]

export type loadstring_func = (source: string, environment: any)->(()->())

local module = {}

StudioService = game:GetService('StudioService')

blank_env = setmetatable({}, {
	__index = function(_, i)
		--print(debug.traceback())
		--error(`Attempting to use environment: {i}`)
		return nil
	end,
})

function module.get_loadstring(): loadstring_func
	local result = assert(loadstring or module.loadstring, `loadstring not found, manually assign loadstring before invoking specific functions in the module`)
	return result
end

function module.set_loadstring(func: loadstring_func)
	module.loadstring = func
end

function module.import(s: string): (boolean, any | string)
	local load_string = module.get_loadstring()
	local success, val = pcall(function()
		return load_string(s, blank_env)()
	end)
	
	if not success then
		warn(`Internal parsing fail: Source={s}|error={val}`)
	end
	
	return success, val
end

function module.import_from_file(): (boolean, any | string)
	local file: File = StudioService:PromptImportFileAsync{'lua'}
	if not file then return false, 'No file selected' end;
	
	return module.import(file:GetBinaryContents())
end

return module
