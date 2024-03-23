-- TYPES
local Objects = script.Parent
local Class = require(Objects.Class)
local Dash = require(Objects["@CHL/DashSingular"])
local Object = require(Objects.Object)
local Set = require(Objects["@CHL/Set"])

type grandfather = Object.object
type set<T> = Set.simple<T>

export type updatable = {
	canUpdate: boolean;
	shouldDisconnect: boolean;
	updatablePriority: number?;

	update: (self:updatable, delta: number) -> nil;
}

export type object = {
	updateThread: thread;
	indexCollection: {number};
	collection: {set<updatable>};

	insertIndex: (self:object, number) -> nil;
	commence: (self:object) -> nil;
	addObject: (self:object, updatable, priority: number?) -> nil;
	removeObject: (self:object, updatable) -> nil;
	update: (self:object, delta: number) -> nil;
	getUpdatables: (self:object) -> {updatable};
} & Class.subclass<grandfather>

-- MAIN
local LuaUTypes = require(Objects.LuaUTypes)
local disguise = require(script.Parent.LuaUTypes).disguise
local abstract = {}

function abstract.new(): object
	local self: object = disguise(Object.new(), abstract)
	self.collection = {}
	self.indexCollection = {}
	
	return self
end

abstract.insertIndex = function(self:object, i: number)
	for j, v in next, self.indexCollection do
		if v > i then continue end
		if v == i then return end;
		
		table.insert(self.indexCollection, j, i)
		
		return
	end
	
	table.insert(self.indexCollection, i)
end

abstract.addObject = function(self:object, u:updatable, p: number?)
	local p = p or u.updatablePriority or 1
	self:insertIndex(p)
	local collection = self.collection
	local map = collection[p] or {}
	
	if not collection[p] then
		collection[p] = map
	end
	
	map[u] = true;
end

abstract.removeObject = function(self:object, u:updatable)
	local map = disguise(self).collection[u.updatablePriority or 1]
	if not map then return end;
	map[u] = nil;
end

abstract.getUpdatables = function(self:object)
	return Dash.keys(Dash.flat(disguise(self.collection)))
end

abstract.update = function(self:object, delta: number)
	for _, v in next, self.indexCollection do
		for u in next, disguise(self).collection[v] do
			if u.shouldDisconnect then self:removeObject(u)continue;end
			if not u.canUpdate then continue end;
			u:update(delta)
		end
	end
end

abstract.__index = abstract
abstract.commence = Class.abstractMethod
abstract.className = '@CHL/RuntimeUpdater'

local module = {}
module.abstract = abstract

local RunService = game:GetService('RunService')

-- heartbeat
local heartBeatUpdater: object = abstract.new()
heartBeatUpdater.commence = function(self:object)
	if self.updateThread then return end
	
	self.updateThread = RunService.Heartbeat:Connect(function(d)self:update(d)end)
end
module.heartBeat = heartBeatUpdater

-- stepped
local steppedUpdater: object = abstract.new()
steppedUpdater.commence = function(self:object)
	if self.updateThread then return end
	self.updateThread = RunService.Stepped:Connect(function(_, d)self:update(d)end)
end
module.stepped = steppedUpdater

-- renderstepped
local renderSteppedUpdater: object = abstract.new()
renderSteppedUpdater.commence = function(self:object)
	assert(RunService:IsClient(), 'attempting to a client exclusive updater on a non client')
	
	self.updateThread = RunService.RenderStepped:Connect(function(d)self:update(d)end)
end
module.renderStepped = renderSteppedUpdater

return module
