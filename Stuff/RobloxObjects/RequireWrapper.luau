-- bare minimum code

local Objects = game:GetService('ReplicatedStorage').Objects
local LuaUTypes = require(Objects.LuaUTypes)
local Set = require(Objects["@CHL>Set"])

export type mode = 'REGULAR' | 'INSTEAD'

module = {}
disguise = LuaUTypes.disguise

module.mode = {}
module.insteads = {}

function module.invoke(any)
	if typeof(any) ~= 'number' then return require(any) end
	
	local result
	local mode = module.mode
	
	if mode.INSTEAD then
		result = module.insteads[any]
	end
	
	if not result and mode.REGULAR then
		result = require(any)
	end
	
	return result
end

function module.init()
	disguise(getfenv)(2).require = module.invoke
end

function module.set_mode(m: mode, b: boolean)
	module.mode[m] = b
end

return module
