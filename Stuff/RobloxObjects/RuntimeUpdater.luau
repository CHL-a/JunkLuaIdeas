-- TYPES
local Object = require('./Object')
local Class = require('./Class')
local Set = require('./@CHL>Set')
local Destructable = require('./@CHL>Destructable')

type set<T> = Set.simple<T>

export type updatable = {
	canUpdate: boolean;
	shouldDisconnect: boolean;
	updatablePriority: number?;

	update: (self:updatable, delta: number) -> ();
} & Destructable.object

export type object = {
	updateThread: thread;
	indexCollection: {number};
	collection: {set<updatable>};

	insertIndex: (self:object, number) -> ();
	commence: (self:object) -> ();
	addObject: (self:object, updatable, priority: number?) -> ();
	removeObject: (self:object, updatable) -> ();
	update: (self:object, delta: number) -> ();
	getUpdatables: (self:object) -> {updatable};
} & Object.object_inheritance

-- MAIN
local LuaUTypes = require('./LuaUTypes')
local abstract = {}

disguise = LuaUTypes.disguise
insert = table.insert

function abstract.new(): object
	local self: object = Object.new():__inherit(abstract)
	self.collection = {}
	self.indexCollection = {}
	
	return self
end

function abstract.insertIndex(self:object, i: number)
	for j, v in self.indexCollection do
		if v > i then continue end
		if v == i then return end;
		
		insert(self.indexCollection, j, i)
		
		return
	end
	
	insert(self.indexCollection, i)
end

function abstract.addObject(self:object, u:updatable, p: number?)
	local p = p or u.updatablePriority or 1
	self:insertIndex(p)
	local collection = self.collection
	local map = collection[p] or {}
	
	if not collection[p] then
		collection[p] = map
	end
	
	map[u] = true;
end

function abstract.removeObject(self:object, u:updatable)
	local map = self.collection[u.updatablePriority or 1]
	if not map then return end;
	map[u] = nil;
end

function abstract.getUpdatables(self:object)
	local result = {}
	
	for _, v in self.collection do
		for w in v do
			insert(result, w)
		end
	end
	
	return result
end

function abstract.update(self:object, delta: number)
	for _, v in self.indexCollection do
		for u in self.collection[v] do
			if u.shouldDisconnect then self:removeObject(u)continue;end
			if not u.canUpdate then continue end;
			u:update(delta)
		end
	end
end

Class.makeProperClass(abstract, '@CHL>RuntimeUpdater')
abstract.commence = Class.abstractMethod

local module = {}
module.abstract = abstract

local RunService = game:GetService('RunService')

-- heartbeat
local heartBeatUpdater: object = abstract.new()

function heartBeatUpdater.commence(self:object)
	if self.updateThread then return end
	
	self.updateThread = RunService.Heartbeat:Connect(function(d)self:update(d)end)
end

heartBeatUpdater.className = '@CHL>RuntimeUpdater>HeartBeat'
module.heartBeat = heartBeatUpdater

-- stepped
local steppedUpdater: object = abstract.new()

function steppedUpdater.commence(self:object)
	if self.updateThread then return end
	self.updateThread = RunService.Stepped:Connect(function(_, d)
		self:update(d)
	end)
end

steppedUpdater.className = '@CHL>RuntimeUpdater>Stepped'
module.stepped = steppedUpdater

-- renderstepped
local renderSteppedUpdater: object = abstract.new()

function renderSteppedUpdater.commence(self:object)
	assert(RunService:IsClient(), 'attempting to a client exclusive updater on a non client')
	
	self.updateThread = RunService.RenderStepped:Connect(function(d)self:update(d)end)
end

renderSteppedUpdater.className = '@CHL>RuntimeUpdater>RenderStepped'
module.renderStepped = renderSteppedUpdater

return module
