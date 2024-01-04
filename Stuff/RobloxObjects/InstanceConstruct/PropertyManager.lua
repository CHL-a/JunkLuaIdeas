--// TYPES
local Shared = script.Parent.Parent
local Types = require(script.Parent.Types)
local LuaUTypes = require(Shared.LuaUTypes)
local Dash = require(Shared["@CHL/DashSingular"])
local TableUtils = require(Shared["@CHL/TableUtils"])

--[[
type __propertyManager = {
	imprint: (Types.resultStruct, Instance, string, any) -> nil;
}
--]]
type __propertyFunction = (Types.resultStruct, Instance, string, any) -> nil;

type __module = {
	classes: {
		[string]: {
			[string] : {
				default: __propertyFunction?;
				[string]: __propertyFunction;
			}
		}
	};
	
	get: (inst: Instance, property: string, value: any) -> __propertyFunction;
	imprint: (Types.resultStruct, Instance, property: string, value: any) -> nil
}

--// MAIN
local disguise = LuaUTypes.disguise

default = function(_, i, p, v)TableUtils.safeSet(i, p, v)end :: __propertyFunction
instanceProperty = function(rStruct , inst, property, value)
	table.insert(rStruct.postAppliedProperties, {
		instance = inst;
		property = property;
		value = assert(rStruct.instances[value], `Can not find instance: Got {value}`)
	} :: Types.postAppliedProperty)
end :: __propertyFunction

--// API
local module = disguise{} :: __module

--// POPULATION
module.classes = {}

module.classes.Weld = {Part0 = {string = instanceProperty};};

module.classes.ModuleScript = {
	Source = {
		string = function(result, inst, p, v: string)
			if Dash.startsWith(v, 'https://') then
				module.classes.ModuleScript.Source.table(result, inst, p, {
					vType = 'url';
					url = v;
				})
			else
				error(`got unknown v: {v}`)
			end
		end,
		table = function(r, i, p, v)
			if v.vType == 'url' then
				local url = assert(v.url, 'Missing v.url')
				disguise(i)[p] = game:GetService('HttpService'):GetAsync(url)
			else
				error(`invalid vType {v.vType}`)
			end
		end :: __propertyFunction,
	};
	Parent = {
		string = instanceProperty;
	}
}

--// METHODS
function module.get(inst: Instance, property: string, value: any) : __propertyFunction
	local set = TableUtils.deepSoftIndex(module.classes, inst.ClassName, property)
	local vType = typeof(value)

	local result: __propertyFunction = set and (set[vType] or set.default) or default
	
	return result
end

function module.imprint(
	rStruct: Types.resultStruct, 
	inst: Instance,
	property: string,
	value: any)
	
	local f = module.get(inst, property, value)
	f(rStruct, inst, property, value)
end


return module
