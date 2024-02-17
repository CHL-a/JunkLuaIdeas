--// TYPES
local Objects = script.Parent
local Class = require(Objects.Class)

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type base = {
	upload: (self: base, content: string, ext: string?) -> string;
}

local module = {}
local LuaUTypes = require(Objects.LuaUTypes)
local Class = require(Objects.Class)

disguise = LuaUTypes.disguise
base = {}
base. __index = base

function base.new(): base
	local self: base = disguise(setmetatable({}, base))
	return self
end

base.upload = Class.abstractMethod

module.base = base

--#####################################################################################
--#####################################################################################
--#####################################################################################

HttpService = game:GetService('HttpService')
hastebin = {}
hastebin.__index = hastebin
hastebin.baseUrl = 'https://hastebin.com'

function hastebin.new(): base return Class.inherit(base.new(), hastebin)end

hastebin.upload = function(self: base, content: string, ext: string?)
	local s, json = pcall(function()
		return HttpService:PostAsync(`{hastebin.baseUrl}/documents`, content)
	end)

	assert(s, json)

	local result = `{hastebin.baseUrl}/raw/{
		HttpService:JSONDecode(json).key}{ext and '.' .. ext or ''}`

	return result
end

module.hastebin = hastebin

return module
