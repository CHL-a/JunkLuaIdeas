local Objects = game:GetService('ReplicatedStorage').Objects

local set = require(Objects["@CHL>Set"])

type set<T> = set.simple<T>

export type environment = {} | (_K: api) -> {}

export type arg_definition = {
	type: string,
	name: string,
	description: string,
	optional: boolean?,
	permissions: set<string>?,
	-- player type options
	lowerRank: boolean?,
	ignoreSelf: boolean?,
	shouldRequest: boolean?,
}

export type command_input = {
	name: string,
	aliases: { string }?,
	description: string,
	-- command group
	group: string,
	noLog: boolean?,
	args: { arg_definition }?,
	permissions: set<string>?,
	envClient: environment?,
	env: environment?,
	runClient: (...any) -> ()?,
	run: (...any) -> ()?,
	_listIndex: number?,
}

export type registry = {
	registerCommand: (K: api, command_input)->();
}

export type api = {
	Registry: registry;
}


local module = {}

module.module = 1868400649

function module.get_K(): api return require(module.module)end

function module.add_command(arg: command_input)
	local K = module.get_K()
	K.Registry.registerCommand(K, arg)
end


return module
