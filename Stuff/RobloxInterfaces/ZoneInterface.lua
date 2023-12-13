--[[
	From: https://1foreverhd.github.io/ZonePlus/api/zone/
--]]

--// TYPES
local Signal = require(script.Parent.SignalInterface)
type __module = {
	new: (container: Instance | BasePart | {BasePart}) -> __object;
	fromRegion: (cframe: CFrame, size: Vector3) -> __object;
};
export type module = __module;

type __detectionEnum = 'WholeBody' | 'Centre'
export type detectionEnum = __detectionEnum

type __accuracyEnum = 'Low' | 'Medium' | 'High' | 'Precise'
export type accuracyEnum = __accuracyEnum

type __item = Model | BasePart  -- what defines an item?
export type item = __item 

type __object = {
	--// methods
	findLocalPlayer: (self: __object) -> boolean;
	findPlayer: (self: __object, player: Player) -> boolean;
	findPart: (self: __object, basePart: BasePart) -> (boolean, {BasePart}?);
	findItem: (self: __object, basePartOrCharacter: __item) -> (boolean, {BasePart}?);
	findPoint: (self: __object, position: Vector3) -> (boolean, {BasePart}?);
	getPlayers: (self: __object) -> {Player};
	getParts: (self: __object) -> {BasePart};
	getItems: (self: __object) -> {__item};
	getRandomPoint: (self: __object) -> (Vector3, {BasePart});
	trackItem: (self: __object, item: __item) -> nil;
	untrackItem: (self: __object, item: __item) -> nil;
	bindToGroup: (self: __object, groupName: string) -> nil;
	unbindFromGroup: (self: __object, groupName: string) -> nil;
	setDetection: (self: __object, string: __detectionEnum) -> nil;
	relocate: (self: __object) -> nil;
	onItemEnter: (self: __object, item: __item, callback: ()->nil) -> nil;
	onItemExit: (self: __object, item: __item, callback: ()->nil) -> nil;
	destroy: (self: __object) -> nil;

	--// events
	localPlayerEntered: Signal.object<>;
	localPlayerExited: Signal.object<>;
	playerEntered: Signal.object<Player>;
	playerExited: Signal.object<Player>;
	partEntered: Signal.object<BasePart>;
	partExited: Signal.object<BasePart>;
	itemEntered: Signal.object<__item>;
	itemExited: Signal.object<__item>;

	--// properties
	accuracy: __accuracyEnum;
	enterDetection: __detectionEnum;
	exitDetection: __detectionEnum;
	autoUpdate: boolean;
	respectUpdateQueue: boolean;
	zoneParts: {BasePart};
	region: Region3;
	volume: number;
	worldModel: WorldModel;
}
export type object = __object

return true;
