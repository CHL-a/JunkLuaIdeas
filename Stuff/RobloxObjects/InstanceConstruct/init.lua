--// TYPES
local LuaUTypes = require(script.Parent.LuaUTypes)
local Types = require(script.Types)

type __instance = Types.instance
export type instance = __instance

type __resultStruct = Types.resultStruct
export type resultStruct = __resultStruct

type __postAppliedProperty = Types.postAppliedProperty

type __inputStruct = Types.inputStruct
export type inputStruct = __inputStruct

--// MAIN
local PropertyManager = require(script.PropertyManager)
local disguise = LuaUTypes.disguise
local module = {}

function compileStruct(resultStruct: __resultStruct, struct: __instance)
	--// pre
	local cN = assert(
		struct.className,
		`Attempting to construct nil class, expected: string, got: {
		struct.className}, from: {struct}`
	)
	local structInstance = Instance.new(cN)
	
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

function module.convertToInstance(iStruct: __inputStruct)
	--// parse inputs
	local icVersion: Types.inputCompileVersion = iStruct.inputCompileVersion or 'base'
	
	if icVersion == 'all_modules' then
		for _, v in next, iStruct.root do
			--// classname
			v.className = 'ModuleScript'
			
			--// properties
			local properties = {}
			
			for i, w in next, v do
				properties[i] = w;
			end
			
			v.properties = properties;
		end
	end
	
	local result = {} :: __resultStruct
	result.instances = {}
	result.root = {}
	result.postAppliedProperties = {}
	
	--// compile
	for _, v in next, iStruct.root do
		local instance = compileStruct(result, v)
		
		if not v.properties.Parent then
			table.insert(result.root, instance)
		end
	end
	
	--// set values for post applied
	for _, v in next, result.postAppliedProperties do
		disguise(v.instance)[v.property] = v.value;
	end
	
	return result
end


return module
