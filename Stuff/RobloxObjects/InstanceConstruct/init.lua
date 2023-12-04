--// TYPES
local LuaUTypes = require(script.Parent.LuaUTypes)
local Types = require(script.Types)

type __instance = Types.instance
export type instance = __instance

type __resultStruct = Types.resultStruct
export type resultStruct = __resultStruct

type __postAppliedProperty = Types.postAppliedProperty

--// MAIN
local PropertyManager = require(script.PropertyManager)
local disguise = LuaUTypes.disguise
local module = {}

function compileStruct(resultStruct: __resultStruct, struct: __instance)
	local structInstance = Instance.new(struct.className)
	
	--// set id
	if struct.id then
		resultStruct.instances[struct.id] = structInstance
	end
	
	--// set values
	if struct.properties then
		for i, v in next, struct.properties do
			PropertyManager.imprint(resultStruct, structInstance, i, v)
		end
	end
	
	--// set children
	if struct.children then
		for _, v in next, struct.children do
			local i = compileStruct(resultStruct, v)
			
			table.insert(resultStruct.postAppliedProperties, {
				instance = i;
				property = 'Parent';
				value = structInstance;
			} :: __postAppliedProperty)
		end
	end
	
	return structInstance
end

function module.convertToInstance(...: __instance)
	local result = {} :: __resultStruct
	result.instances = {}
	result.root = {}
	result.postAppliedProperties = {}
	
	--// compile
	for i = 1, select('#', ...)do
		local struct = select(i, ...)
		table.insert(result.root, compileStruct(result, struct))
	end
	
	--// set values for post applied
	for _, v in next, result.postAppliedProperties do
		disguise(v.instance)[v.property] = v.value;
	end
	
	return result
end


return module
