local Objects = game:GetService('ReplicatedStorage').Objects
local Map = require(Objects["@CHL>Map"])

type map<I,V> = Map.simple<I,V>
type dict<T> = Map.dictionary<T>
type map_any = map<any, any>
type dict_any = dict<any>

-- subject to expansion
export type hda_settings = {
	-- is an array of multiple values:
	-- rank_num: number, rank_name: string, specific_user: {username: string, userid: number}
	Rank: {any};
	Gamepasses: map<number, string>;
	Assets: map<number, string>;
	Groups: map<number, map<number, string>>;
	Friends: string;
	VipServerOwner: string;
	FreeAdmin: string;
	Banned: {any}; -- denotes {username: string, userid: number};
	Prefix: string;
	SplitKey: string;
	BatchKey: string;
	QualifierBatchKey: string;
	AppTheme: string;

	NoticeSoundId: number;
	NoticeVolume: number;
	NoticePitch: number;

	ErrorSoundId: number;
	ErrorVolume: number;
	ErrorPitch: number;

	AlertSoundId: number;
	Alert2SoundId: number;
	AlertVolume: number;
	AlertPitch: number;

	WelcomeBadgeId: number;

	CommandDebounce: boolean;
	SaveRank: boolean;
	LoopCommands: number;
	MusicList: {number};

	AppThemes: {any}; -- denoted as {name: string, color: Color3};

	Colors: {any}; -- denoted as {short_name: string, long_name: string, color: Color3};
	
	Cmdbar: number;
	Cmdbar2: number;
	ViewBanland: number;
	OnlyShowUsableCommands: boolean;
	RankRequiredToViewPage: {
		Commands: number;
		Moderation: number;
		Settings: number;
	};
	RankRequiredToViewRank: dict< number>;
	RankRequiredToViewRankType: {
		Owner: number;
		SpecificUsers: number;
		Gamepasses: number;
		Assets: number;
		Groups: number;
		Friends: number;
		FreeAdmin: number;
		VipServerOwner: number;
	};
	RankRequiredToViewIcon: number;
	DisableFunCommands: boolean;
	WelcomeRankNotice: boolean;
	WelcomeBoosterNotice: boolean;
	WarnIncorrectPrefix: boolean;
	DisableAllNotices: boolean;
	ScaleLimit: number;
	IgnoreScaleLimit: number;
	CommandLimits: dict<{
		Limit: number;
		IgnoreLimit: number;
	}>;
	CommandLimitPerMinute: number;
	IgnoreCommandLimitPerMinute: number;
	VIPServerCommandBlacklist: {string};
	GearBlacklist: {number};
	IgnoreGearBlacklist: number;
	PlayerDataStoreVersion: string;
	SystemDataStoreVersion: string;
	CoreNotices: dict<any>;
	ChatVoiceAutoEnabled: boolean;
	ChatVoiceRequiredRank: number;
	SetCommandRankByName: dict<string>;
	SetCommandRankByTag: dict<string>;
	
	UniversalPrefix: string;
	ChatPrefix: string;
}

export type hda_modules = {
	cf: any;
	ClientCoreFunctions: any;
	SharedCoreFunctions: any;
	ServerCoreFunctions: any;
	
	API: any;
	ClientAPI: any;
	ServerAPI: any;
	SharedAPI: any;
	
	CommandHandler: {
		Setup: (self: any)->();
	};
	Commands: {command};
	Extensions: {
		SetupItem: (self: any, Player, item_name: string, did_respawn: boolean)->();
	};
	
}

export type api = {
	alreadyInitialized: boolean?;
	hdAdminCoreName: 'System'; 

	rs: ReplicatedStorage;
	sss: ServerScriptService;
	ss: ServerStorage;
	starterPlayer: StarterPlayer;
	starterGui: StarterGui;
	replicatedFirst: ReplicatedFirst;
	players: Players;
	physicsService: PhysicsService;
	
	mainModule: ModuleScript;
	server: Folder;
	client: Folder;
	workspaceFolder: Folder;
	
	coreFolder: Folder;
	moduleGroup: Folder;
	sharedModules: Folder;
	signals: Folder;
	audio: Folder;
	
	settings: hda_settings;
	modules: hda_modules;
	
	GetModule: <A>(self: api, name: string)->A;
	loadModule: <A>(name: string)->A;
	
	hdAdminGroup: {
		Id: number;
		Info: {any};
	};
	hdAdminGroupInfo: {};
	settingsBanRecords: {};
	alphabet: {string};
	UserIdsFromName: {any};
	UsernamesFromUserId: {any};
	validSettings: {string};
	commandInfoToShowOnClient: {string};
	productCooldown: number;
	products: {
		Booster: number;
		LaserEyes: number;
		Donor: number;
	};
	materials: {string};
	rankTypes: {
		Auto: number;
		Perm: number;
		Server: number;
		Temp: number;
	};
	
	pd: map_any;
	sd: map_any;
	permissions: {
		specificUsers: map_any;
		gamepasses: map_any;
		assets: map_any;
		groups: map_any;
		friends: number;
		freeAdmin: number;
		vipServerOwner: number;
		vipServerPlayer: number;
		owner: boolean
	};
	commandInfo: map_any;
	commandRanks: map_any;
	infoOnAllCommands: {
		Contributors: map_any;	--table
		Tags: map_any;			--table
		Prefixes: dict_any;		--dictionary
		Aliases: dict_any;		--dictionary
		UndoAliases: dict_any;		--dictionary
		ChatCommands: map_any;
	};
	
	morphNames : map_any;
	toolNames : map_any;

	commands: map_any;
	playersRanked: map_any;
	playersUnranked: map_any;
	serverAdmins : map_any;
	owner: map_any;
	ownerId: number;
	ownerName: string;
	isGroupGame: boolean;
	gameInfo: {Name: string};
	gameName: string;
	listOfTools: map_any;
	ranksAllowedToJoin: number;
	permissionToReplyToPrivateMessage: map_any;
	logs: {
		command: map_any;
		chat: map_any;
	};
	isStudio: boolean;
	serverBans: map_any;
	blacklistedVipServerCommands: map_any;
	banned: map_any;
	commandBlocks: map_any;
}

export type command = {
	Name: string;
	Aliases: {string};
	Prefixes: {string};
	IsBooster: boolean?;
	Rank: (number | string)?;
	RankName: string?;
	Tags: {string}?;
	Args: {string}?;
	SpecialColors: boolean?;
	Function: <A>(speaker: Player, args: A, self: command)->();

	DisableChatUndo: boolean?;
	CanUndo: boolean?;
	UnFunction: (<A>(speaker: Player, args: A, self: command)->())?;
}

module = {}
module.current_asset = 3239236979
module.main = nil

function module.load_admin(loader: Folder)
	require(module.current_asset).initialize(loader)
end

function module.get_main(can_be_nil: boolean?): api
	local result = module.main or _G.HDAdmin
	
	if not module.main then
		module.main = result
	end
	
	if not can_be_nil then
		assert(result, 'Failed to load.')
	end
	
	return result
end

function getCommandTables(command: command)
	local lowed = command.Name:lower()
	local main = module.get_main()
	local template, modified = {},{}

	for dataName, data in command do
		if main:GetModule("cf"):FindValue(main.commandInfoToShowOnClient, dataName) then
			template[dataName] = data
		end

		if (dataName == "UnFunction" and type(data) == "function") or (dataName == "CanUndo" and data == true) then
			template["UnFunction"] = `un{lowed}`--string.gsub(commandNameLower, "%a", function(c) return string.upper(c) end, 1)
		end

		modified[dataName] = data 
	end
	--
	local lowerCaseArgs = {}
	if command.Args then
		for i,v in pairs(command.Args) do
			table.insert(lowerCaseArgs, string.lower(v))
		end
	end
	template.RankName = main:GetModule("cf"):GetRankName(command.Rank)
	if template.IsBooster then
		--template.RankName = "Booster"
	end
	template.Args = lowerCaseArgs
	modified.Args = lowerCaseArgs
	--
	return template, modified	
end

function module.add_command(command: command)
	local main = module.get_main()

	if command.UnFunction and command.CanUndo == nil then command.CanUndo = true end
	--ChangeRankRequiredToUseCommand
	local prefixes = command.Prefixes
	local chatPrefix = main.settings.ChatPrefix

	if table.find(prefixes, chatPrefix) then
		local names = {command.Name}
		local aliases = command.Aliases or {}
		for _, alias in aliases do
			table.insert(names, alias)
		end
		for _, name in names do
			local lowerName = name:lower()
			
			if command.DisableChatUndo then continue end
			
			lowerName = "un"..lowerName
		end
	end

	local commandName = command.Name:lower()
	local changeRankByNameSetting = main.settings.ChangeRankRequiredToUseCommand or main.settings.SetCommandRankByName
	local changeRank = changeRankByNameSetting[command.Name] or changeRankByNameSetting[commandName]

	if tonumber(command.Rank) == nil then
		if command.Rank == "Booster" then
			command.IsBooster = true
			command.RankName = "Booster"
		end
		command.Rank = 5
	elseif changeRank then
		if tonumber(changeRank) == nil then
			changeRank = main:GetModule("cf"):GetRankId(changeRank)
		end
		command.Rank = changeRank
	elseif commandName == "cmdbar" or commandName == "cmdbar2"  then
		local settingName = commandName:gsub("^%a", function(c) return(string.upper(c)) end)
		local setting = main.settings[settingName]
		if setting then
			if tonumber(setting) == nil then
				setting = main:GetModule("cf"):GetRankId(setting)
			end
			command.Rank = setting
			main.settings[settingName] = setting
		end
	end

	local cbafd = main.settings.DisableFunCommands -- HD Admin relies on this as its sole source of income. Please consider keeping so that we can continue to improve the application and build more powerful monetization features to increase your earnings directly from HD Admin.
	local tags = command.Tags
	local nufString = 'fun'

	if cbafd and tags and typeof(tags) == "table" then
		for _, gat in tags do
			if gat:lower() ~= nufString then continue end
			return;
		end
	end

	if commandName == "" then return end

	local infoTemplate, modifiedCommand = getCommandTables(command)
	table.insert(main.commandInfo, infoTemplate)
	main.commands[commandName] = modifiedCommand

	--Special Colors
	if command.SpecialColors then
		for i,v in main.settings.Colors do
			local shortName = v[1]

			if shortName == "w" then continue end

			local newTemplate, newModifiedCommand = getCommandTables(command)
			local commandColorName = command.Name..shortName
			local color = v[3]

			newTemplate.SpecialColor = color
			newTemplate.SpecialColorName = shortName
			newTemplate.OriginalName = command.Name
			newTemplate.Name = commandColorName

			newModifiedCommand.SpecialColor = color
			newModifiedCommand.Name = commandColorName
			newModifiedCommand.OriginalName = command.Name

			table.insert(main.commandInfo, newTemplate)
			main.commands[commandColorName] = newModifiedCommand
		end
	end
	--
	for infoName, infoTable in main.infoOnAllCommands do
		local commandStat = command[infoName]

		if type(commandStat) ~= "table" then continue end

		for i,v in commandStat do
			if infoName ~= "Contributors" then
				v = v:lower()
			end

			if infoName == "Contributors" or infoName == "Tags" then
				if infoName == "Contributors" and tonumber(v) then
					v = main.main:GetModule("cf"):GetName(v)
				end
				local statCount = main.infoOnAllCommands[infoName][v]
				if statCount == nil then
					--if infoName ~= "Contributors" or not isCustomCommands then
					main.infoOnAllCommands[infoName][v] = 1
					--end
				else
					main.infoOnAllCommands[infoName][v] = statCount + 1
				end
			elseif infoName == "Aliases" or infoName == "UndoAliases" then
				main.infoOnAllCommands[infoName][v] = commandName
			else
				main.infoOnAllCommands[infoName][v] = true
			end
		end
	end

	main.commandRanks[commandName] = command.Rank
end

return module
