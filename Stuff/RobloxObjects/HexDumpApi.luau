local module = {}

local AttributeApi = require('./@CHL>AttributeApi')
local BufferWrapper = require('./@CHL>BufferWrapper')
local EventPackage = require('./EventPackage')

module.api_events = {}
module.queued_args = {}
module.a_api = AttributeApi.new(game:GetService('ServerScriptService'), '__hexdump_api_')

-- called again because apparently, plugins reload code on server run
function upon_invoke()
	if not game:GetService('RunService'):IsStudio() then return end

	local api = module.a_api
	local call_type: string = api:get('type')
	local arg;

	if not api:get('invoke') then return end

	api:set('invoke', nil)
	api:set('type', nil)
	arg = api:get_dictionary()

	for i, v in arg do
		api:set(i, nil)
	end

	local resolve_functions = module.api_events[call_type]

	if resolve_functions then
		for i, v: EventPackage.package<any> in resolve_functions do
			v:fire(arg)
		end
	else
		table.insert(module.queued_args, {
			arg = arg;
			call_type = call_type;
		})
	end
end

function api_assign<A>(a_type: string)
	return function(arg: A)
		module.invoke_api(a_type, arg)
	end
end

function module.invoke_api(a_type: string, args)
	module.a_api:set_dictionary(args)
	module.a_api:set('type', a_type)
	module.a_api:set('invoke', true)
end

function module.upon_api_invoke<A>(specific_api_call: string)
	local api_events = module.api_events

	if not api_events[specific_api_call] then
		api_events[specific_api_call] = {}
	end

	local list = api_events[specific_api_call]

	local package = EventPackage.new()

	table.insert(list, package)
	
	local queued_args = module.queued_args
	-- i dont like this approach but this is the only way to make it work
	-- purpose: intentionally delay package firing to allow dev to set up
	-- event connections, then fire queued args after
	if #queued_args > 0 then
		task.delay(1, function()
			local i = 1
			
			while queued_args[i] do
				local arg = queued_args[i]
				
				while arg and arg.call_type ~= specific_api_call do
					i += 1
					arg = queued_args[i]
				end
				
				if arg then
					package:fire(arg.arg)
					table.remove(queued_args, i)
				else
					i += 1
				end
			end
		end)
	end
	
	return package.event
end

export type view_arg = {
	content: string;
	encoding: 'base64'?;
}

module.view = api_assign('view') :: (view_arg) -> ()

export type compare_arg = {
	content_1: string;
	content_2: string;
}

module.compare = api_assign('compare') :: (compare_arg) -> ()

-- specific function used for plugins/hex dump only
function module.plugin_init(plugin: Plugin)
	if not plugin or not plugin:IsA('Plugin') then return end
	
	module.a_api.instance:GetAttributeChangedSignal(`{module.a_api.prefix}invoke`):Connect(upon_invoke)
	
	upon_invoke()
end

return module
