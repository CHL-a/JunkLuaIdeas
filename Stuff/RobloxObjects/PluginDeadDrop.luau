local BinaryFormat1 = require('./@CHL>BinaryFormat1')
local PluginToolset = require('./@CHL>PluginToolset')
local Dash = require('./@roblox>Dash')
local Base64 = require('./@CHL>Base64')
local StringUtils = require('./@CHL>StringUtils')

local module = {}

function module.to_medium<T>(value: T, explicit_type: number?): string
	local iterator = BinaryFormat1.serializer_0.new(value)
	local consumer = StringUtils.consumer.byte.new()
	
	iterator = Base64.encoder.encoder_iterator.new(iterator)
	
	consumer:dump(iterator)
	
	return consumer:get_string()
end

function module.from_medium<T>(value: string): T
	local iterator = Base64.decoder.decoder_iterator.new(StringUtils.iterator.byte.new(value))
	local deserializer = BinaryFormat1.deserializer_0.from.byte_iterator(iterator)
	
	deserializer:all()
	
	return deserializer.result
end

function module.stash<T>(dead_drop_location: string, value: T)
	local plugin = assert(PluginToolset.promised_plugin:expect(), 'plugin only')
	local str = module.to_medium(value)
	
	plugin:SetSetting(dead_drop_location, str)
end

function module.retrieve<T>(dead_drop_location: string): T
	local plugin = assert(PluginToolset.promised_plugin:expect(), 'plugin only')
	local str = plugin:GetSetting(dead_drop_location)
	
	return module.from_medium(str)
end

return module
