--[[
	Returns an animation based on input
]]

local Object = require('./Object')
local Map = require('./@CHL>Map')
local Class = require('./Class')

type map<I,V> = Map.simple<I,V>

export type object = {
	get: (self: object, input: any)->Content;
}

local module = {}

KeyframeSequenceProvider = game:GetService('KeyframeSequenceProvider')

function module.new(): object
	local self: object = Object.simple.new(module)
	
	return self
end

module.get = Class.abstractMethod

module.__index = module

return module
