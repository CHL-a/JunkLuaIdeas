local Object = require('./Object')
local Class = require('./Class')
local Quaternion = require('./@CHL>Quaternion')
local Spring = require('./@CHL>Spring')

export type quaternion = Quaternion.object

local module = {}

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

function module.time_skip(
	p_0: quaternion,
	v: Vector3, 
	p_1: quaternion, 
	d: number, 
	s: number,
	dt: number): (quaternion, Vector3)
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
	
	local new_p, new_v
	
	new_p = p_0:s_lerp(p_1, a1):integrate(v, a2)
	new_v = p_0:q_difference(p_1):to_euler_vector() * b1 + v * b2
	
	return new_p, new_v
end

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

export type timeless =  {
	velocity: Vector3;
	
	impulse: (self: timeless, velocity: Vector3) -> ();
} & Spring.timeless<quaternion>

timeless = {}

function timeless.new(position_0: quaternion): timeless
	local self: timeless = Object.simple.new(timeless)
	
	self.position = position_0
	self.velocity = Vector3.zero
	self.target = position_0
	self.damper = 1
	self.speed = 1
	self.enabled = true
	
	return self
end

function timeless.time_skip(self: timeless, dt: number): (quaternion, Vector3)
	return module.time_skip(self.position, self.velocity, self.target, self.damper, self.speed, dt)
end

timeless.impulse = Spring.timeless.impulse
timeless.update = Spring.timeless.update

Class.make_proper_class(timeless, '@CHL>QuaternionSpring>Timeless')

module.timeless = timeless

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

export type temporal = Spring.temporal<quaternion>

temporal = {}

function temporal.new(init_position: quaternion?, clock: (()->number)?): temporal
	local self: temporal = Object.simple.new(temporal)
	
	self.timeless = timeless.new(init_position or Quaternion.object.identity)
	if clock then self.clock = clock end
	self.timestamp = self.clock()
	
	return self
end

temporal.get = Spring.temporal.get
temporal.get_temporal_difference = Spring.temporal.get_temporal_difference
temporal.get_dt = temporal.get_temporal_difference
temporal.get_position = Spring.temporal.get_position
temporal.get_velocity = Spring.temporal.get_velocity
temporal.get_target = Spring.temporal.get_target
temporal.get_damper = Spring.temporal.get_damper
temporal.get_speed = Spring.temporal.get_speed
temporal.is_enabled = Spring.temporal.is_enabled

temporal.set = Spring.temporal.set
temporal.set_position = Spring.temporal.set_position
temporal.set_velocity = Spring.temporal.set_velocity
temporal.set_target = Spring.temporal.set_target
temporal.set_damper = Spring.temporal.set_damper
temporal.set_speed = Spring.temporal.set_speed
temporal.set_enabled = Spring.temporal.set_enabled

temporal.time_skip = Spring.temporal.time_skip
temporal.clock = Spring.temporal.clock
temporal.impulse = Spring.temporal.impulse
temporal.update = Spring.temporal.update
temporal.time_skip_now = Spring.temporal.time_skip_now

Class.make_proper_class(temporal, '@CHL>QuaternionSpring>Temporal')

module.temporal = temporal

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################


return module
