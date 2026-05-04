--[[
	From https://eryn.io/Cmdr/guide/Setup.html

]]

local shared = require('@game/ReplicatedStorage/Objects/@CHL>Cmdr>Api>Shared')
local RemoteFolder = require('@game/ReplicatedStorage/Objects/@CHL>RemoteFolder')
local LuaUTypes = require('@game/ReplicatedStorage/Objects/LuaUTypes')
local InstanceUtils = require('@game/ReplicatedStorage/Objects/@CHL>InstanceUtils')

export type registry = {
	-- attempts to register commands of a container, with modulescript children
	RegisterTypesIn: (self: registry, container: Instance)->();
	-- Registers all hooks from within a container on both the server and the client. If you want to add a hook to the server or the client
	-- only (not on both), then you should use the Registry.RegisterHook method directly by requiring Cmdr in a server or client script.
	RegisterHooksIn: (self: registry, container: Instance)->();
	-- Registers all commands from within a container.
	RegisterCommandsIn: (self: registry, container: Instance)->();
	RegisterCommand: (self: registry, commandScript: ModuleScript, commandServerScript: ModuleScript?, filter: ((command: shared.command_definition) -> boolean)?)->();
	RegisterDefaultCommands: (self: registry, groups: {string})->();
} & shared.registry

export type cmdr = {
	Registry: registry;
} & shared.cmdr

export type command_definition = shared.command_definition

--############################################################################################################################################################
--############################################################################################################################################################
--############################################################################################################################################################

local module = {}

function module.get_module(): cmdr return require('./@evaera>Cmdr') end

function module.quick_set_up(): cmdr
	local cmdr = module.get_module()
	
	cmdr.Registry:RegisterDefaultCommands()
	
	return cmdr
end

function module.get_remote_event(): RemoteEvent return RemoteFolder.static_get_event('cmdr_api_event') end

function module.get_remote_function(): RemoteFunction return RemoteFolder.static_get_function('cmdr_api_callback') end

function module.connect_client_bridge()
	if module.client_connected then return end
	
	local cmdr = module.get_module()
	RemoteFolder.construct()
	
	module.get_remote_event()
	
	local remote_function = module.get_remote_function()
	
	function remote_function.OnServerInvoke(player, index, ...)
		if index == 'get_command_definitions' then
			return module.used_command_definitions
		elseif index == 'get_type_definitions' then
			return module.registered_returnable_types
		end
		
		error('unknown')
	end
	
	module.client_connected = true
end

module.used_command_definitions = {}

function module.add_command(command_def: shared.command_definition, server_upon: (shared.command_context, ...any)->())
	local cmdr = module.get_module()
	
	if module.client_connected then
		module.get_remote_event():FireAllClients('register_command', command_def)
		table.insert(module.used_command_definitions, table.clone(command_def))
	end
	
	command_def.Run = assert(server_upon)
	
	cmdr.Registry:RegisterCommandObject(command_def)
end

function module.add_super_user_hook()
	local cmdr = module.get_module()
	
	cmdr.Registry:RegisterHook('BeforeRun', LuaUTypes.empty)
end

function get_or_create_folder(parent: Instance, name: string): Folder return InstanceUtils.get_or_create(parent, name, 'Folder') end

function module.get_main_remotes_folder(): Folder return get_or_create_folder(game:GetService('ReplicatedStorage'), 'Remotes') end

function module.get_remote_folder(...: string)
	local parent = module.get_main_remotes_folder()
	
	for i = 1, select('#', ...) do
		local name = select(i, ...)
		
		parent = get_or_create_folder(parent, name)
	end
	
	return parent
end

module.registered_returnable_types = {}

function module.add_type(name: string, type_definition: shared.type_definition)
	local cmdr = module.get_module()
	
	if module.client_connected then
		local returnable_type = table.clone(type_definition)
		
		for i, v in returnable_type do
			if typeof(v) ~= 'function' then continue end
			
			local parent_folder = module.get_remote_folder('Types', name)
			local remote_function_i: RemoteFunction = InstanceUtils.get_or_create(parent_folder, i, 'RemoteFunction')
			
			function remote_function_i.OnServerInvoke(player: Player, ...) return type_definition[i](...) end
			
			returnable_type[i] = true
		end
		
		module.registered_returnable_types[name] = returnable_type
		module.get_remote_event():FireAllClients('register_type', returnable_type)
	end
	
	cmdr.Registry:RegisterType(name, type_definition)
end

function module.get_type(name: string)
	return module.get_module().Registry:GetType(name)
end

function module.evaluate_and_run(cmd: string, player: Player): string
	return module.get_module().Dispatcher:EvaluateAndRun(cmd, player)
end

function module.bulk_evaluate_and_run(cmd: string, player: Player): {any}
	local lines = cmd:split('\n')
	local dispatcher = module.get_module().Dispatcher
	local i = 1
	for _, line in lines do
		local prespace, content = line:match('(%s*)(%S.+)%s*')
		
		if content then
			lines[i] = dispatcher:EvaluateAndRun(content, player) 
			i += 1
		end
	end
	
	for j = i, #lines do
		lines[j] = nil
	end
	
	return lines
end

return module
