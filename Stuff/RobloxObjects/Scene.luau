local Object = require('./Object')
local Class = require('./Class')
local EventPackage = require('./EventPackage')

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type abstract<A...> = {
	isRunning: boolean;
	isInSkip: boolean;

	runScene: (self: abstract<A...>, A...) -> ();
	selfWait: (self: abstract<A...>, number) -> ();
	-- Subjected to yielding
	play: (self: abstract<A...>, A...) -> ();

	__completed: EventPackage.package<>;
	completed: EventPackage.event<>;
} & Object.object_inheritance

Abstract = {}

function Abstract.new<A...>(): abstract<A...>
	local self: abstract<A...> = Object.from.class(Abstract)
	
	self.isInSkip = false
	self:__constructEvent('completed')
	
	return self
end

function Abstract.selfWait<A...>(self: abstract<A...>, n: number)
	if not self.isInSkip then
		wait(n)
	end
end

Abstract.play = Class.abstractMethod
Abstract.runScene = Class.unimplemented

Class.makeProperClass(Abstract, '@CHL>Scene>Abstract')

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type singleton<A...> = {
	-- Subjected to yielding
	play: (self: singleton<A...>, A...) -> ();
} & Class.subclass<abstract<A...>>

Singleton = {}

function Singleton.new<A...>() : singleton<A...>
	return Abstract.new():__inherit(Singleton)
end

function Singleton.play<A...>(self: singleton<A...>, ...: A...)
	if self.isRunning then return end;

	self.isRunning = true
	self:runScene()
	self.isRunning = false
	self.__completed:fire()
end

Class.makeProperClass(Singleton, '@CHL>Scene>Singleton')

--##########################################################################################
--##########################################################################################
--##########################################################################################

local RuntimeUpdater = require('./@CHL>RuntimeUpdater')
local LuaUTypes = require('./LuaUTypes')
local TableUtils = require('./@CHL>TableUtils')

export type continuous<A> = {
	meta: A;
	elapsed: number;
	
	play: (self:continuous<A>, A?) -> ();
	pause: (self: continuous<A>) -> ();
	stop: (self: continuous<A>) -> ();
} & Class.subclass<abstract<A>>
  & RuntimeUpdater.updatable

Continuous = {}

disguise = LuaUTypes.disguise

function Continuous.new<A>(init: A?): continuous<A>
	local self: continuous<A> = Abstract.new():__inherit(Continuous)
	
	self.meta = disguise(init)
	self.elapsed = 0
	
	return self
end

function Continuous.play<A>(self: continuous<A>, a: A)
	if self.meta then
		TableUtils.imprint(self.meta, disguise(a))
	else
		self.meta = a
	end
	self.isRunning = true
	self.canUpdate = true
end

function Continuous.update<A>(self: continuous<A>, dt: number)self.elapsed += dt;end
function Continuous.pause<A>(self: continuous<A>)self.canUpdate = false;end

Class.makeProperClass(Continuous, '@CHL>Scene>Continuous')

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type hybrid<A> = {
	runScene: (self: hybrid<A>) -> ();
} & continuous<A> 

Hybrid = {}

function Hybrid.new<A>(init: A): hybrid<A>
	local self: hybrid<A> = Abstract.new():__inherit(Hybrid)

	self.meta = disguise(init)
	self.elapsed = 0
	
	return self
end

function Hybrid.play<A>(self: hybrid<A>, a: A)
	Continuous.play(self, a)
	self:runScene()
end

Hybrid.update = Continuous.update

Class.makeProperClass(Hybrid, '@CHL>Scene>Hybrid')

--##########################################################################################
--##########################################################################################
--##########################################################################################

module = {}
module.abstract = Abstract
module.singleton = Singleton
module.continuous = Continuous
module.hybrid = Hybrid

return module
