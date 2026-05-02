--[[
	From https://eryn.io/Cmdr/guide/Setup.html

]]

local shared = require('@game/ReplicatedStorage/Objects/@CHL>Cmdr>Api>Shared')
local RemoteFolder = require('@game/ReplicatedStorage/Objects/@CHL>RemoteFolder')
local LuaUTypes = require('@game/ReplicatedStorage/Objects/LuaUTypes')

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

return module
