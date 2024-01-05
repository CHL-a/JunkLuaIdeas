--// TYPES
local Objects = script.Parent
local Iterator = require(Objects["@CHL/Iterator"])
local MapInterface = require(Objects["@CHL/MapInterface"])
local Class = require(Objects.Class)

type __entryIterator<A> = {
	i: number;
	t: {ObjectValue};
} & Class.subclass<Iterator.object<string, A>>

type __kIterator = {
	it: __entryIterator<any>;
} & Class.subclass<Iterator.object<string>>

type __vIterator<A> = {
	it: __entryIterator<A>;
} & Class.subclass<Iterator.object<string>>


type __object<A> = {
	folder: Folder;
	
	getPointer: (self: __object<A>, i: string) -> ObjectValue?;
	getPointers: (self: __object<A>) -> {ObjectValue};
} & MapInterface.object<string, A>
export type object<A> = __object<A>

--// MAIN

-- iterators
local disguise = require(Objects.LuaUTypes).disguise

local EntryIterator = {}

EntryIterator.__index = EntryIterator

function EntryIterator.new<A>(ovs: {ObjectValue})
	local self: __entryIterator<A> = disguise(Class.inherit(Iterator.new(), EntryIterator))
	
	self.t = ovs
	self.i = 1
	
	return self
end

EntryIterator.canProceed = function<A>(self: __entryIterator<A>)return self.i <= #self.t end

EntryIterator.proceed = function<A>(self: __entryIterator<A>)
	local i, v = self.i, self.t[self.i]
	self.i += 1
	return i, v
end

local KIterator = {}

KIterator.__index = KIterator

function KIterator.new(ovs: {ObjectValue})
	local self: __kIterator = disguise(Class.inherit(Iterator.new(), KIterator))
	self.it = EntryIterator.new(ovs);
	return self
end

KIterator.canProceed = function(self: __kIterator)return self.it:canProceed()end
KIterator.proceed = function(self: __kIterator)local i = self.it:proceed()return i end

local VIterator = {}

VIterator.__index = VIterator

function VIterator.new<A>(ovs: {ObjectValue})
	local self: __vIterator<A> = disguise(Class.inherit(Iterator.new(), VIterator))
	self.it = EntryIterator.new(ovs);
	return self
end

VIterator.canProceed = KIterator.canProceed
VIterator.proceed=function<A>(self:__vIterator<A>)local _,v=self.it:proceed()return v end

--// module
local module = {}
local Debris = game:GetService('Debris')
local Dash = require(Objects["@CHL/DashSingular"])

local compose = Dash.compose

module.__index = module

function module.new<A>(folder: Folder)
	local self: __object<A> = disguise(setmetatable({}, module))
	
	self.folder = folder
	
	return self
end

module.clear = function<A>(self: __object<A>)self.folder:ClearAllChildren()end
module.has =function<A>(self:__object<A>,i:string)return not not self:getPointer(i)end
module.getPointers = function<A>(self: __object<A>)return self.folder:GetChildren()end
module.getSize = function<A>(self: __object<A>)return #self:getPointers()end
module.entries = compose(module.getPointers, EntryIterator.new)
module.keys = compose(module.getPointers, KIterator.new)
module.values = compose(module.getPointers,VIterator.new)

module.getPointer = function<A>(self: __object<A>, i: string)
	local o = self.folder:FindFirstChild(i)
	return o:IsA('ObjectValue') and o or nil;
end

module.get = function<A>(self: __object<A>, i: string)
	local o = self:getPointer(i)
	return o and o.Value
end

module.delete = function<A>(self:__object<A>, i: string)
	local p = self:getPointer(i)
	if p then
		Debris:AddItem(p)
		return true
	end
	
	return false
end

module.set = function<A>(self: __object<A>, i: string, v: A)
	local o = self:getPointer(i)
	
	if not o then
		local ov = Instance.new('ObjectValue')
		ov.Name = i;
		ov.Parent = self.folder
		o = ov
	end
	
	o.Value = v;
end

module.forEach = function<A>(self:__object<A>, fn: (v: A, i: string) -> any?)
	Dash.forEach(self:entries(), fn)
end



return module
