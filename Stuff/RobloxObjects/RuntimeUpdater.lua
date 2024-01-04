-- type
local Objects = script.Parent
local Class = require(Objects.Class)
local Dash = require(Objects["@CHL/DashSingular"])

type __updatable = {
	canUpdate: boolean;
	shouldDisconnect: boolean;
	updatablePriority: number?;
	
	update: (self:__updatable, delta: number) -> nil;
}
export type updatable = __updatable
type __object = {
	updateThread: thread;
	indexCollection: {number};
	collection: {{[__updatable]: true}};
	
	insertIndex: (self:__object, number) -> nil;
	commence: (self:__object) -> nil;
	addObject: (self:__object, __updatable, priority: number?) -> nil;
	removeObject: (self:__object, __updatable) -> nil;
	update: (self:__object, delta: number) -> nil;
	getUpdatables: (self:__object) -> {__updatable};
}
export type object = __object

-- main
local disguise = require(script.Parent.LuaUTypes).disguise
local abstract = {}
abstract.__index = abstract
abstract.new = function()
	local self: __object = disguise(setmetatable({}, abstract))
	self.collection = {}
	self.indexCollection = {}
	
	return self
end

abstract.commence = Class.abstractMethod
abstract.insertIndex = function(self:__object, i: number)
	for j, v in next, self.indexCollection do
		if v > i then continue end
		if v == i then return end;
		
		table.insert(self.indexCollection, j, i)
		
		return
	end
	
	table.insert(self.indexCollection, i)
end

abstract.addObject = function(self:__object, u:__updatable, p: number?)
	local p = p or u.updatablePriority or 1
	self:insertIndex(p)
	local collection = self.collection
	local map = collection[p] or {}
	
	if not collection[p] then
		collection[p] = map
	end
	
	map[u] = true;
end
abstract.removeObject = function(self:__object, u:__updatable)
	local map = self.collection[u.updatablePriority or 1]
	if not map then return end;
	map[u] = nil;
end
abstract.getUpdatables = function(self:__object)
	return Dash.keys(Dash.flat(disguise(self.collection)))
end

abstract.update = function(self:__object, delta: number)
	for _, v in next, self.indexCollection do
		for u in next, self.collection[v] do
			if u.shouldDisconnect then self:removeObject(u)continue;end
			if not u.canUpdate then continue end;
			u:update(delta)
		end
	end
end


local module = {}
module.abstract = abstract

local RunService = game:GetService('RunService')

-- heartbeat
local heartBeatUpdater: __object = abstract.new()
heartBeatUpdater.commence = function(self:__object)
	if self.updateThread then return end
	
	self.updateThread = RunService.Heartbeat:Connect(function(d)self:update(d)end)
end
module.heartBeat = heartBeatUpdater

-- stepped
local steppedUpdater: __object = abstract.new()
steppedUpdater.commence = function(self:__object)
	if self.updateThread then return end
	self.updateThread = RunService.Stepped:Connect(function(_, d)self:update(d)end)
end
module.stepped = steppedUpdater

-- renderstepped
local renderSteppedUpdater: __object = abstract.new()
renderSteppedUpdater.commence = function(self:__object)
	assert(RunService:IsClient(), 'attempting to a client exclusive updater on a non client')
	
	self.updateThread = RunService.RenderStepped:Connect(function(d)self:update(d)end)
end
module.renderStepped = renderSteppedUpdater

return module
