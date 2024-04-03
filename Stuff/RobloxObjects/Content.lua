-- TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type protocol = 'rbxassetid' | 'rbxasset' | 'rbxthumb' | 'rbxhttp' | 'https' | 
	'http'

export type object = {
	protocol: protocol;
	suffix: string;
	
	toString: (self: object) -> string;
} & Class.subclass<Object.object>

-- MAIN
local module = {}

from = {}

function module.new(protocol: protocol, suffix: string)
	local self: object = Object.new():__inherit(module)
	
	self.protocol = protocol
	self.suffix = suffix
	
	return self
end

function from.singleString(s: string)
	local p, s = s:match('(%l+)://(.*)')
	return module.new(p, s)
end

module.toString = function(self: object)return `{self.protocol}://{self.suffix}`end

module.from = from
module.__index = module
module.className = '@CHL/Content'

return module
