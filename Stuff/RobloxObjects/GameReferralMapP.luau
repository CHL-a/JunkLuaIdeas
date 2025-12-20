--// TYPES
local Iterator = require('./@CHL>Iterator')
local MapInterface = require('./@CHL>MapInterface')
local Class = require('./Class')

type simple_iterator<A, B...> = Iterator.simple<A, B...>

--// MAIN

-- iterators

disguise = require('./LuaUTypes').disguise

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- entry iterator

export type entry_iterator<A> = {
	i: number;
	t: {ObjectValue};
} & simple_iterator<string, A>

local Object = require('./Object')

EntryIterator = {}

function EntryIterator.new<A>(ovs: {ObjectValue}): entry_iterator<A>
	local self: entry_iterator<A> = Object.simple.new(EntryIterator)
	
	self.t = ovs
	self.i = 1
	
	return self
end

function EntryIterator.can_proceed<A>(self: entry_iterator<A>)return self.i <= #self.t end

function EntryIterator.proceed<A>(self: entry_iterator<A>)
	local i, v = self.i, self.t[self.i]
	self.i += 1
	return i, v
end

Iterator.simple.declare_as(EntryIterator)
Class.make_proper_class(EntryIterator, '@CHL>GameReferralMap>EntryIterator')

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- key iterator

export type key_iterator = {
	iterator: entry_iterator<any>
} & simple_iterator<string>

KeyIterator = {}

function KeyIterator.new(ovs: {ObjectValue}): key_iterator
	local self: key_iterator = Object.simple.new(KeyIterator)
	self.iterator = EntryIterator.new(ovs);
	return self
end

function KeyIterator.can_proceed(self: key_iterator)return self.iterator:can_proceed()end
function KeyIterator.proceed(self: key_iterator)local i = self.iterator:proceed()return i end

Iterator.simple.declare_as(KeyIterator)
Class.make_proper_class(KeyIterator, '@CHL>GameReferralMap>KeyIterator')

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- value iterator

export type value_iterator<A> = {
	iterator: entry_iterator<A>
} & simple_iterator<A>

ValueIterator = {}

function ValueIterator.new<A>(ovs: {ObjectValue}): value_iterator<A>
	local self: value_iterator<A> = Object.simple.new(ValueIterator)
	self.iterator = EntryIterator.new(ovs);
	return self
end

function ValueIterator.proceed<A>(self:value_iterator<A>)local _,v=self.iterator:proceed()return v end

ValueIterator.canProceed = KeyIterator.canProceed
Iterator.simple.declare_as(ValueIterator)
Class.makeProperClass(ValueIterator, '@CHL>GameReferralMap>ValueIterator')

--#####################################################################################
--#####################################################################################
--#####################################################################################

--// module

export type object<A> = {
	folder: Folder;

	get_pointer: (self: object<A>, i: string) -> ObjectValue?;
	get_pointers: (self: object<A>) -> {ObjectValue};
} & MapInterface.object<string, A>

local module = {}
local Debris = game:GetService('Debris')
local Dash = require('./@CHL>DashSingular')

compose = Dash.compose

function module.new<A>(folder: Folder): object<A>
	local self: object<A> = Object.simple.new(module)
	
	self.folder = folder
	
	return self
end

function module.clear<A>(self: object<A>)self.folder:ClearAllChildren()end
function module.has<A>(self:object<A>,i:string)return not not self:get_pointer(i)end
function module.get_pointers<A>(self: object<A>)return self.folder:GetChildren()end
function module.getSize<A>(self: object<A>)return #self:get_pointers()end

module.entries = compose(module.get_pointers, EntryIterator.new)
module.keys = compose(module.get_pointers, KeyIterator.new)
module.values = compose(module.get_pointers, ValueIterator.new)

function module.get_pointer<A>(self: object<A>, i: string)
	local o = self.folder:FindFirstChild(i)
	return o and o:IsA('ObjectValue') and o or nil;
end

function module.get<A>(self: object<A>, i: string)
	local o = self:get_pointer(i)
	return o and o.Value
end

function module.delete<A>(self: object<A>, i: string)
	local p = self:get_pointer(i)
	if p then
		Debris:AddItem(p, 0)
	end
	
	return not not p
end

function module.set<A>(self: object<A>, i: string, v: A)
	local o = self:get_pointer(i)
	
	if not o then
		local ov = Instance.new('ObjectValue')
		ov.Name = i;
		ov.Parent = self.folder
		o = ov
	end
	
	o.Value = v;
end

function module.for_each<A>(self: object<A>, fn: (v: A, i: string) -> any?)
	Dash.forEach(self:entries(), fn)
end

Class.make_proper_class(module, '@CHL>GameReferralMap')

return module
