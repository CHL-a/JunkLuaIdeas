local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)
local EventPackage = require(Objects.EventPackage)

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
} & Class.subclass<Object.object>

local Abstract = {}

function Abstract.new<A...>(): abstract<A...>
	local self: abstract<A...> = Object.new():__inherit(Abstract)
	
	self.isInSkip = false
	self:__constructEvent('completed')
	
	return self
end

Abstract.selfWait = function<A...>(self: abstract<A...>, n: number)
	if not self.isInSkip then
		wait(n)
	end
end

Abstract.play = Class.abstractMethod
Abstract.runScene = Class.unimplemented

Abstract.__index = Abstract
Abstract.className = '@CHL/Scene/Abstract'

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type singleton<A...> = {
	-- Subjected to yielding
	play: (self: singleton<A...>, A...) -> ();
} & Class.subclass<abstract<A...>>

local Singleton = {}

function Singleton.new<A...>() : singleton<A...>
	return Abstract.new():__inherit(Singleton)
end

Singleton.play = function<A...>(self: singleton<A...>, ...: A...)
	if self.isRunning then return end;

	self.isRunning = true
	self:runScene()
	self.isRunning = false
	self.__completed:fire()
end

Singleton.__index = Singleton
Singleton.className = '@CHL/Scene/Singleton'

--##########################################################################################
--##########################################################################################
--##########################################################################################

local RuntimeUpdater = require(Objects.RuntimeUpdater)
local LuaUTypes = require(Objects.LuaUTypes)
local TableUtils = require(Objects["@CHL/TableUtils"])

export type continuous<A> = {
	meta: A;
	elapsed: number;
	
	play: (self:continuous<A>, A?) -> ();
	pause: (self: continuous<A>) -> ();
	stop: (self: continuous<A>) -> ();
} & Class.subclass<abstract<A>>
  & RuntimeUpdater.updatable

local Continuous = {}

disguise = LuaUTypes.disguise

function Continuous.new<A>(init: A?): continuous<A>
	local self: continuous<A> = Abstract.new():__inherit(Continuous)
	
	self.meta = disguise(init)
	self.elapsed = 0
	
	return self
end

Continuous.play = function<A>(self: continuous<A>, a: A)
	if self.meta then
		TableUtils.imprint(self.meta, disguise(a))
	else
		self.meta = a
	end
	self.isRunning = true
	self.canUpdate = true
end

Continuous.update = function<A>(self: continuous<A>, dt: number)self.elapsed += dt;end
Continuous.pause = function<A>(self: continuous<A>)self.canUpdate = false;end
Continuous.__index = Continuous
Continuous.className = '@CHL/Scene/Continuous'

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type hybrid<A> = {
	runScene: (self: hybrid<A>) -> ();
} & continuous<A> 

local Hybrid = {}

function Hybrid.new<A>(init: A): hybrid<A>
	local self: hybrid<A> = Abstract.new():__inherit(Hybrid)

	self.meta = disguise(init)
	self.elapsed = 0
	
	return self
end

Hybrid.play = function<A>(self: hybrid<A>, a: A)
	Continuous.play(self, a)
	self:runScene()
end

Hybrid.update = Continuous.update


Hybrid.__index = Hybrid
Hybrid.className = '@CHL/Scene/Hybrid'

--##########################################################################################
--##########################################################################################
--##########################################################################################

module = {}
module.abstract = Abstract
module.singleton = Singleton
module.continuous = Continuous
module.hybrid = Hybrid

return module
