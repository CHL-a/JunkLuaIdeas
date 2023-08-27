-- type
local Class = require(script.Parent.Class)
type __updatable = {
	canUpdate: boolean;
	shouldDisconnect: boolean;
	update: (self:__updatable, delta: number) -> nil;
}
export type updatable = __updatable
type __object = {
	updateThread:thread;
	collection: {[__updatable]: true};
	commence: (self:__object) -> nil;
	addObject: (self:__object, __updatable) -> nil;
	removeObject: (self:__object, __updatable) -> nil;
	update: (self:__object, delta: number) -> nil
}
export type object = __object

-- main
local disguise = require(script.Parent.LuaUTypes).disguise
local abstract = {}
abstract.__index = abstract
abstract.new = function()
	local self: __object = disguise(setmetatable({}, abstract))
	self.collection = {}
	
	return self
end

abstract.commence = Class.abstractMethod
abstract.addObject = function(self:__object, u:__updatable)self.collection[u] = true; end
abstract.removeObject = function(self:__object, u:__updatable)self.collection[u] = nil; end

abstract.update = function(self:__object, delta: number)
	for u in next, self.collection do
		if u.shouldDisconnect then self:removeObject(u)continue;end
		if not u.canUpdate then continue end;
		u:update(delta)
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
