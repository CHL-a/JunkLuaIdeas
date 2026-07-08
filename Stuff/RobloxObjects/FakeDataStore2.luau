--[[
	another version of fake datastore where the option to load data is given, implements over FakeDataStore

	Current API:
	
	type game_data = {
		[DATASTORE_NAME] = {
			[KEY] = VALUE
		}
	}
	
	.import_data(game_data): imports all data and resumes all service calls
	.import_data_from_json(string): imports all data from json and resumes all service calls
	.init(): initializes saving data with either of the following
	.EXPLICIT_PRINT = boolean: toggles output generation with printing to output
	.DISCORD_WEBHOOK = string: sends all data to this webhook
]]

local module = {}

local FakeDataStore = require('./@CHL>FakeDataStore')
local Map = require('@game/ReplicatedStorage/Objects/@CHL>Map')
local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')
local Encoders = require('@game/ReplicatedStorage/Objects/@CHL>RobloxServiceEncoders')
local Dash = require('@game/ReplicatedStorage/Objects/@roblox>Dash')

type promise<T...> = Promise.modified_object<T...>
type dict<T> = Map.dictionary<T>

export type game_data = dict< dict<any> >

Dash.promise:await()

json_encode = Encoders.encoding.json.encode
compose = Dash.compose
empty = require('@game/ReplicatedStorage/Objects/LuaUTypes').empty

function module.import_data_raw(import_specs: game_data)
	local singleton = module.singleton
	
	for name, data in import_specs do
		local datastore = singleton:GetDataStore(name)
		
		datastore.data = data
	end
end

function module.import_data(data: game_data)module.bulk_data:resolve(data)end

local original_get_datastore = FakeDataStore.service.GetDataStore
local original_get_ordered_datastore = FakeDataStore.service.GetDataStore

function FakeDataStore.service.GetDataStore(self, name, scope)
	module.bulk_data:await()
	
	return original_get_datastore(self, name, scope)
end

function FakeDataStore.service.GetOrderedDataStore(self, name, scope)
	module.bulk_data:await()
	
	return original_get_ordered_datastore(self, name, scope)
end

function module.export_data(): game_data
	local result = {}
	
	local singleton = module.singleton
	
	for name, datastore in singleton.data_stores do
		result[name] = datastore.data
	end
	
	return result
end

function module.print_output(data: game_data)
	if not module.EXPLICIT_PRINT then
		return
	end
	
	print('Copy json below:\n', json_encode(data))
end

function module.invoke_webhook(data: game_data)
	local webhook = module.DISCORD_WEBHOOK
	
	if not webhook then return end
	
	local DiscordWebhook = require('./@CHL>DiscordWebhook')
	local webhook_object: DiscordWebhook.object = module.webhook_object or DiscordWebhook.object.from.url(webhook)
	
	if not module.webhook_object then
		module.webhook_object = webhook_object
	end
	
	webhook_object.payload.content = `Export Type:\n\`\`\`\njson\n\`\`\`\nData:\n\`\`\`\n{ json_encode(data) }\n\`\`\``
	
	webhook_object:post()
end

function module.init()
	game:BindToClose(function()
		local data = module.export_data()
		
		module.print_output(data)
		module.invoke_webhook(data)
	end)
end

module.import_data_from_json = compose(Encoders.encoding.json.decode, module.import_data) :: (string) -> () 

module.singleton = FakeDataStore.singleton
module.bulk_data = Promise.new(empty)
module.bulk_data:upon(module.import_data_raw)
module.DISCORD_WEBHOOK = nil
module.EXPLICIT_PRINT = false

return module
