local module = {}

--############################################################################################################################################################
--############################################################################################################################################################
--############################################################################################################################################################

-- types
local Map = require('./@CHL>Map')
local Set = require('./@CHL>Set')

type set<T> = Set.simple<T>
type map<I, V> = Map.simple<I, V>
type any_map = map<any, any>

export type type_definition = {
	-- Optionally overrides the user-facing name of this type in the autocomplete menu. If omitted, the registered name of this type will be used.
	DisplayName: string?;
	
	-- String containing default Prefixed Union Types for this type. This property should omit the initial type name, so this string should begin 
	-- with a prefix character, e.g. Prefixes = "# integer ! boolean".
	Prefixes: string;
	
	-- Transform is an optional function that is passed two values: the raw text, and the player running the command. Then, whatever values this 
	-- function returns will be passed to all other functions in the type (Validate, Autocomplete, and Parse).
	Transform: (<T>(raw_text: string, player: Player)->T)?;
	
	-- The Validate function is passed whatever is returned from the Transform function (or the raw value if there is no Transform function). If 
	-- the value is valid for the type, it should return true. If it the value is invalid, it should return two values: false, and a string 
	-- containing an error message.
	-- If this function isn't present, anything will be considered valid.
	Validate: (<T>(transformed_value: T, player: Player)->(boolean, string?))?;
	
	-- This function works exactly the same as the normal Validate function, except it only runs once (after the user presses Enter). This should 
	-- only be used if the validation process is relatively expensive or needs to yield. For example, the PlayerId type uses this because it needs 
	-- to call GetUserIdFromNameAsync in order to validate.
	-- For the vast majority of types, you should just use Validate instead.
	ValidateOnce: (<T>(transformed_value: T, player: Player)->(boolean, string?))?;
	
	-- Should only be present for types that are possible to be auto completed. It should return an array of strings that will be displayed in the
	-- auto complete menu. It can also return a second value, which can be a dictionary with options such as IsPartial as described.
	-- If IsPartial is true, pressing Tab to auto complete won't continue onwards to the next argument.
	Autocomplete: (<T>(transformed_value: T)->({string}, {IsPartial: boolean?}?))?;
	
	-- Parse is the only required function in a type definition. It is the final step before the value is considered finalized. This function 
	-- should return the actual parsed value that will be sent to the command functions.
	Parse: <T, U>(value: T) -> U;
	
	-- The Default function is optional and should return the "default" value for this type, as a string. For example, the default value of the 
	-- players type is the name of the player who ran the command.
	Default: ((player: Player) -> string)?;

	-- If you set the optional key Listable to true in your table, this will tell Cmdr that comma-separated lists are allowed for this type. 
	-- Cmdr will automatically split the list and parse each segment through your Transform, Validate, Autocomplete, and Parse functions 
	-- individually, so you don't have to change the logic of your Type at all.
	-- The only limitation is that your Parse function must return a table. The tables from each individual segment's Parse will be merged into 
	-- one table at the end of the parse step. The uniqueness of values is ensured upon merging, so even if the user lists the same value several
	-- times, it will only appear once in the final table.
	Listable: boolean?
}

export type argument_definition = {
	-- The argument type (case sensitive), or an inline TypeDefinition object
	Type: string | type_definition;
	
	-- The argument name, this is displayed to the user as they type.
	Name: string;
	
	-- A description of what the argument is, this is also displayed to the user.
	Description: string;
	
	-- If this is present and set to true, then the user can run the command without filling out this value. The argument will be sent to 
	-- your commands as nil.
	Optional: boolean?;
	
	-- If present, the argument will be optional and if the user doesn't supply a value, your function will receive whatever you set this 
	-- to. Default being set implies Optional = true, so Optional can be omitted.
	Default: any?
}

export type command_definition = {
	-- The name that's in auto complete and displayed to user.
	Name: string;
	
	-- Aliases that are not in the autocomplete, but if matched will run this command just the same. For example, m might be an alias of announce.
	Aliases: {string}?; 
	
	-- A description of the command which is displayed to the user.
	Description: string;
	
	-- Optional, can be be any value you wish. This property is intended to be used in hooks, so that you can categorize commands and decide if you 
	-- want a specific user to be able to run them or not.
	Group: any?;
	
	-- Array of CommandArgument objects, or functions that return CommandArgument objects.
	Args: {argument_definition | <A>(context: A)->argument_definition}
}

export type dispatcher = {
	Cmdr: cmdr;
	
	EvaluateAndRun: (self: dispatcher, text: string, player: Player?, options: {
		Data: any?;
		IsHuman: boolean
	}?)-> string;
}

export type dispatcher_client = {
	Run: (self: dispatcher, ...string)->string;
	GetHistory: (self: dispatcher_client)->{string};
} & dispatcher

export type command_context = {
	Cmdr: cmdr;
	Dispatcher: dispatcher;
	Name: string;
	
	--The specific alias of this command that was used to trigger this command (may be the same as Name)
	Alias: string;
	RawText: string;
	
	-- The group this command is a part of. Defined in command definitions, typically a string.
	Group: string?;
	
	-- A blank table that can be used to store user-defined information about this command's current execution. This could potentially 
	-- be used with hooks to add information to this table which your command or other hooks could consume.
	State: any_map;
	Aliases: {string};
	Description: string;
	Executor: Player;
	RawArguments: {string};
	
	--The command output, if the command has already been run. Typically only accessible in the AfterRun hook.
	Response: string?;
	
	GetArgument: (self: command_context, index: number)->argument_definition;
	GetData: <T>(self: command_context)->T;
	-- Returns a table of the given name. Always returns the same table on subsequent calls. Useful for storing things like ban information. 
	-- Same as Registry.GetStore.
	GetStore: (self: command_context, name: string)->any_map;
	-- Sends a network event of the given name to the given player. See Network Event Handlers.
	SendEvent: (self: command_context, player: Player, event: string)->();
	-- Broadcasts a network event to all players. See Network Event Handlers.
	BroadcastEvent: (self: command_context, event: string, ...any)->();
	-- Prints the given text in the user's console. Useful for when a command needs to print more than one message or is long-running. You 
	-- should still return a string from the command implementation when you are finished, Reply should only be used to send additional 
	-- messages before the final message.
	Reply: (self: command_context, text: string, color: Color3?)->();
	-- Returns true if the command has an implementation on this machine. For example, this function will return false from the client if you 
	-- call it on a command that only has a server-side implementation. Note that commands can potentially run on both the client and the server,
	-- so what this property returns on the server is not related to what it returns on the client, and vice versa. Likewise, receiving a return 
	-- value of true on the client does not mean that the command won't run on the server, because Cmdr commands can run a first part on the
	-- client and a second part on the server. This function only answers one question if you run the command; does it run any code as a result
	-- of that on this machine?
	HasImplementation: (self: command_context)->boolean;
}

export type registry = {
	cmdr: cmdr;
	RegisterType: (self: registry, name: string, _type: type_definition)->();
	
	-- Registers a Prefixed Union Type string for the given type. If there are already type prefixes for the given type name, they will 
	-- be concatenated. This allows you to contribute prefixes for default types, like players.
	RegisterTypePrefix: (self: registry, name: string, union: string)->();
	RegisterTypeAlias: (self: registry, name: string, union: string)->();
	GetType: (self: registry, name: string)->type_definition?;
	GetTypeName: (self: registry, name: string)->string?;
	GetCommand: (self: registry, name: string)->command_definition?;
	GetCommands: (self: registry)->{command_definition};
	GetCommandNames: (self: registry)->{string};
	-- Adds a hook. This should probably be run on the server, but can also work on the client. Hooks run in order of priority (lower number runs first).
	RegisterHook: (self: registry, 
		hookName: "BeforeRun" | "AfterRun",
		callback: (context: command_context) -> string?,
		priority: number?
	)->();
	
	-- Returns a table saved with the given name. This is the same as CommandContext.GetStore
	GetStore: (name: string)->any_map;
}

export type cmdr = {
	Registry: registry;
	Dispatcher: dispatcher
}

export type cmdr_client = {
	Enabled: boolean;
	PlaceName: string;
	ActivationKey: set<Enum.KeyCode>;
	
	SetActivationKeys: (self: cmdr_client, keys: Set.array_set<Enum.KeyCode>)->();
	
	-- Sets the place name label that appears when executing commands. This is useful for a quick way to tell what game you're playing in a universe game.
	SetPlaceName: (self: cmdr_client, name: string)->();
	
	SetEnabled: (self: cmdr_client, enabled: boolean)->();
	Show: (self: cmdr_client)->();
	Hide: (self: cmdr_client)->();
	Toggle: (self: cmdr_client)->();
	HandleEvent: (self: cmdr_client, event: string, callback: (...any)->())->();
	SetMashToEnable: (self: cmdr_client, enabled: boolean)->();
	SetActivationUnlocksMouse: (self: cmdr_client, enabled: boolean)->();
	SetHideOnLostFocus: (self: cmdr_client, enabled: boolean)->();
} & cmdr

--############################################################################################################################################################
--############################################################################################################################################################
--############################################################################################################################################################

local RemoteFolder = require('./@CHL>RemoteFolder')

module.module_script = nil

function module.get_module_script(refuse_wait: boolean): ModuleScript
	if module.module_script then
		return module.module_script
	end
	
	local cmdr_module_script = script.Parent.Parent:FindFirstChild('CmdrClient')
	
	if not cmdr_module_script and not refuse_wait then
		cmdr_module_script = script.Parent.Parent:WaitForChild('CmdrClient', 10)
	end
	
	module.module_script = cmdr_module_script
	
	assert(cmdr_module_script, 'No module, did you forget to initialize on the server?')
	return cmdr_module_script
end

function module.get_module(): cmdr_client return require(module.get_module_script()) end

function module.quick_set_up(): cmdr_client
	local cmdr = module.get_module()
	
	cmdr:SetActivationKeys({ Enum.KeyCode.RightBracket, Enum.KeyCode.RightCurly })
	
	return cmdr
end

function module.get_remote_event(): RemoteEvent return RemoteFolder.static_get_event('cmdr_api_event') end
function module.get_remote_function(): RemoteFunction return RemoteFolder.static_get_function('cmdr_api_callback') end

function module.connect_client_bridge()
	RemoteFolder.construct()
	
	module.get_remote_event().OnClientEvent:Connect(function(...)
		print('met', ...)
	end)
	
	local used_cmds = module.get_remote_function():InvokeServer('get_command_definitions')
	for _, cmd_def in used_cmds do
		module.get_module().Registry:RegisterCommandObject(cmd_def)
	end
end


return module
