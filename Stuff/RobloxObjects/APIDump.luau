export type member_security = "RobloxSecurity" | 'LocalUserSecurity' | 'None' | 
	'NotAccessibleSecurity' | 'PluginSecurity' | 'RobloxScriptSecurity'
export type member_type = "Property" | 'Callback' | 'Event' | 'Function'
export type super_tag = {
	PreferredDescriptorName: string;
	ThreadSafety: string;
}
export type member_tag = "Hidden" | "NonScriptable" | 'CanYield' | 'CustomLuaState' | 
	'Deprecated' | 'NoYield' | 'NotBrowsable' | 'NotReplicated' | 'ReadOnly' | 
	'WriteOnly' | 'Yields' | super_tag
export type member_thread_safety = "ReadSafe" | 'Safe' | 'Unsafe'
export type member_value_type_category = "DataType" | 'Primative' | 'Class' | 'Enum'
export type value_type = {
	Category: member_value_type_category;
	Name: any;
}
export type member = {
	Capabilities: any?;
	Parameters: {
		{
			Name: string;
			Type: value_type;
		}
	}?;
	ReturnType: value_type?;
	
	Category: string?;
	Default: any?;
	MemberType: member_type;
	Name: string;
	Security: {
		Read: member_security?;
		Write: member_security?;
	}?;
	Serialization: {
		CanLoad: boolean?;
		CanSave: boolean?;
	}?;
	Tags: {member_tag}?;
	ThreadSafety: member_thread_safety;
	ValueType: value_type?;
}
export type class_tag = 'NotCreatable' | 'NotReplicated' | 'Deprecated' | 'NotBrowsable' |
	'PlayerReplicated' | 'Service' | 'Settings' | 'UserSettings' | super_tag
export type class = {
	Tags: {class_tag}?;
	Superclass: string;
	Name: string;
	MemoryCatogory: string;
	Members: {member};
};
export type enum_item = {
	Name: string;
	Value: number;
}
export type enum_group = {
	Name: string;
	Items: {enum_item}
}
export type api = {
	Version: number;
	Enums: {enum_group};
	Classes: {class}
}

local Objects = script.Parent
local module = {}

disguise = require(Objects.LuaUTypes).disguise
HttpService = game:GetService('HttpService')

module.url = 'https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/Mini-API-Dump.json'
module.api = disguise() :: api
module.class_indices = {}
module.enum_indices = {}

function module.get_api(): (api?, boolean)
	local c, s = nil, true
	
	if module.api then
		c = module.api
	elseif script:FindFirstChild('pre_import') then
		c = require(disguise(script):FindFirstChild('pre_import'))
	else
		s, c = pcall(function()
			return HttpService:JSONDecode(HttpService:GetAsync(module.url))
		end)
	end
	
	if not module.api and s then
		module.api = c
	end
	
	return c, s
end

function module.get_class_by_name(name: string): class?
	local api, success = module.get_api()
	
	if not success then
		error(`Expected api, got: {api}`)
	end
	
	if name == "<<<ROOT>>>" then
		return 
	end
	
	local i = module.class_indices[name]
	
	if i then return api.Classes[i]end
	
	local class
	for a, b in api.Classes do
		if b.Name == name then
			i = a
			class = b
			break
		end
	end
	
	module.class_indices[name] = i
	return class
end

function module.get_ancestry_by_classname(name: string): {string}
	local result = {}
	local current = module.get_class_by_name(name)
	
	while current do
		table.insert(result, current.Name)
		current = module.get_class_by_name(current.Superclass)
	end
	
	
	return result
end

return module
