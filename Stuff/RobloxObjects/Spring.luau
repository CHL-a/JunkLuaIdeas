--[[
	A version of spring where the math is derived from NevermoreEngine
	
	made because the nevermore engine preemptively uses update regardless of the actual time it's in

	https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua#L98
]]
export type timeless<T> = {
	position: T;
	velocity: T;
	target: T;
	damper: number;
	speed: number;
	enabled: boolean;
	
	impulse: (self: timeless<T>, velocity: T) -> ();
	time_skip: (self: timeless<T>, dt: number) -> (T, T);
	update: (self: timeless<T>, dt: number) -> ();
}

-- type
local Class = require('./Class')
local Object = require('./Object')

-- main
local module = {}

timeless = {}
disguise = require('./LuaUTypes').disguise
temporal = {}

module.timeless = timeless

Class.make_proper_class(timeless, '@CHL>Spring>Timeless')

function timeless.new<T>(position_0: T): timeless<T>
	
	local self: timeless<T> = Object.simple.new(timeless)
	
	self.position = position_0
	self.velocity = disguise(0 * disguise(position_0))
	self.target = position_0
	self.damper = 1
	self.speed = 1
	self.enabled = true
	
	return self
end

function timeless.impulse<T>(self: timeless<T>, velocity: T) disguise(self).velocity += velocity end

--[[
	the main state fetch function
]]
function module.time_skip<T>(
	p_0: T, 
	v: T, 
	p_1: T, 
	d: number, 
	s: number,
	dt: number): (T, T)
	local d2 = d * d
	local t = s * dt
	
	local h, si, co
	if d2 < 1 then
		h = math.sqrt(1 - d2)
		local ep = math.exp(-d * t) / h
		co, si = ep * math.cos(h * t), ep * math.sin(h * t)
	elseif d2 == 1 then
		h = 1
		local ep = math.exp(-d * t) / h
		co, si = ep, ep * t
	else
		h = math.sqrt(d2 - 1)
		local u = math.exp((-d + h) * t) / (2 * h)
		local v = math.exp((-d - h) * t) / (2 * h)
		co, si = u + v, u - v
	end
	
	local a0 = h * co + d * si
	local a1 = 1 - a0
	local a2 = si / s
	
	local b0 = -s * si
	local b1 = -b0
	local b2 = h * co - d * si
	
	return a0 * p_0 + a1 * p_1 + a2 * v,
	       b0 * p_0 + b1 * p_1 + b2 * v
end

function timeless.time_skip<T>(self: timeless<T>, dt)
	return module.time_skip(self.position, self.velocity, self.target, self.damper, self.speed, dt)
end

function timeless.update<T>(self: timeless<T>, dt: number)
	if not self.enabled then return end
	local p, v
	
	repeat
		local p_0, v_0 = self.position, self.velocity
		p, v = self:time_skip(dt)
		local p_1, v_1 = self.position, self.velocity
	until p_0 == p_1 and v_0 == v_1
	
	self.position = p
	self.velocity = v
end

--##################################################################################################################################################
--##################################################################################################################################################
--##################################################################################################################################################

--[[
	Mimics Nevermore's spring
]]

export type temporal<T> = {
	timeless: timeless<T>;
	
	clock: () -> number;
	timestamp: number;
	
	get_temporal_difference: (self: temporal<T>) -> number;
	get_dt: (self: temporal<T>) -> number; -- alias of above
	
	get_position: (self: temporal<T>) -> T;
	get_velocity: (self: temporal<T>) -> T;
	get_target: (self: temporal<T>) -> T;
	get_damper: (self: temporal<T>) -> number;
	get_speed: (self: temporal<T>) -> number;
	is_enabled: (self: temporal<T>) -> boolean;
	
	set_position: (self: temporal<T>, value: T) -> ();
	set_velocity: (self: temporal<T>, value: T) -> ();
	set_target: (self: temporal<T>, value: T) -> ();
	set_damper: (self: temporal<T>, value: number) -> ();
	set_speed: (self: temporal<T>, value: number) -> ();
	set_enabled: (self: temporal<T>, value: boolean) -> ();
	
	time_skip: (self: temporal<T>, dt: number) -> (T, T);
	time_skip_now: (self: temporal<T>) -> (T, T);
	update: (self: temporal<T>, dt: number) -> ();
	impulse: (self: temporal<T>, velocity: T) -> ();
}

temporal = {}

function temporal.new<T>(init_position: T, clock: (()->number)?): temporal<T>
	local self: temporal<T> = Object.simple.new(temporal)
	
	self.timeless = timeless.new(init_position)
	if clock then self.clock = clock end
	self.timestamp = self.clock()
	
	return self
end

function temporal.get_temporal_difference<T>(self: temporal<T>) return self.clock() - self.timestamp end
function temporal.time_skip<T>(self: temporal<T>, dt: number) return self.timeless:time_skip(dt) end
function temporal.time_skip_now<T>(self: temporal<T>) return self:time_skip(self:get_dt()) end
function temporal.clock() return workspace.DistributedGameTime end
function temporal_get_factory(index: string)return function<T>(self: temporal<T>) return self.timeless[index] end end
function temporal.impulse<T>(self: temporal<T>, velocity: T)self:set_velocity(disguise(self):get_velocity() + velocity)end

function temporal.update<T>(self: temporal<T>, dt: number)
	local timeless = self.timeless
	dt += self:get_dt()
	local position, velocity = self:time_skip(dt)
	timeless.position = position
	timeless.velocity = velocity
	self.timestamp = self.clock()
end

function temporal.set_position<T>(self: temporal<T>, position: T)
	local _, velocity = self:time_skip_now()
	self.timeless.position = position
	self.timeless.velocity = velocity
	self.timestamp = self.clock()
end

function temporal.set_velocity<T>(self: temporal<T>, velocity: T)
	local position = disguise(self):time_skip_now()
	self.timeless.position = position
	self.timeless.velocity = velocity
	self.timestamp = self.clock()
end

function temporal_set_factory(index: string)
	return function<T>(self: temporal<T>, value: T)
		local timeless = self.timeless
		local position, velocity = self:time_skip_now()
		timeless.position = position
		timeless.velocity = velocity
		timeless[index] = value
		self.timestamp = self.clock()
	end
end

temporal.get_dt = temporal.get_temporal_difference

temporal.get_position = temporal_get_factory('position')
temporal.get_velocity = temporal_get_factory('velocity')
temporal.get_target = temporal_get_factory('target')
temporal.get_damper = temporal_get_factory('damper')
temporal.get_speed = temporal_get_factory('speed')
temporal.is_enabled = temporal_get_factory('enabled')

temporal.set_target = temporal_set_factory('target')
temporal.set_damper = temporal_set_factory('damper')
temporal.set_speed = temporal_set_factory('speed')
temporal.set_enabled = temporal_set_factory('enabled')

Class.make_proper_class(temporal, '@CHL>Spring>Temporal')

module.temporal = temporal

--##################################################################################################################################################
--##################################################################################################################################################
--##################################################################################################################################################

return module
