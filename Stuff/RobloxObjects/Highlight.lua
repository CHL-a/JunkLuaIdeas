local Objects = script.Parent
local TableUtils = require(Objects["@CHL/TableUtils"])

local module = {}


disguise = require(Objects.LuaUTypes).disguise

module.population = 0
module.objects = {}

function module.can_register(): boolean
	return module.population < 31
end

function module.register(): Highlight
	if module.can_register() then
		warn('Attempting to register too many highlights')
		return disguise()
	end
	
	module.population += 1
	
	local result = Instance.new('Highlight', script)
	
	module.objects[module.population] = result
	
	return result
end

export type query = {
	FillColor: Color3?;
	FillTransparency: number?;
	OutlineColor: Color3?;
	OutlineTransparency: number?;
	Adornee: Instance?;
	DepthMode: Enum.HighlightDepthMode?;
}

function module.find(q: query): {Highlight}
	local result = table.clone(module.objects)
	
	for i, v in next, q do
		if not v then continue end
		
		local j = 1
		
		while j <= #result do
			if result[j][i] ~= v then
				table.remove(result, j)
				continue
			end
			
			j+=1
		end
	end
	
	return result
end

--[[
	Notes: Returns
		1. Highlight, always returned but not always desired
		2. bool, always returned, denotes desirability
		3. int, may not be returned, denotes desirability from query
--]]
function module.getOrCreate(q: query): (Highlight, boolean, number?)
	local found = module.find(q)
	local result = found[1]
	
	if result then
		return result, true, #found
	elseif module.can_register() then
		result = module.register()
		
		TableUtils.imprint(result, q, true)
		
		return result, true
	else
		return module.objects[1], false
	end
end

return module
