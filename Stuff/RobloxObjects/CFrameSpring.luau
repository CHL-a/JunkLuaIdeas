--[[
	A version of Spring from Engine Nevermore which attempts to implement the same logic but using the CFrame
	
	see https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua
	
	For this module, all rotational vector3s are taken in as degrees
--]]

local Object = require('./Object')
local NevermoreSpring = require('./NevermoreSpring')
local Dash = require('./@CHL>DashSingular')
local Quaternion = require('./Quaternion')
local QuaternionSpring = require('./QuaternionSpring')

type quaternion = Quaternion.Quaternion
type quaternion_spring = QuaternionSpring.QuaternionSpring
type spring<T> = NevermoreSpring.Spring<T>

export type clock = NevermoreSpring.SpringClock

export type object = {
	position_spring: spring<Vector3>;
	rotation_spring: quaternion_spring;
	
	impulse: (self: object, position: Vector3?, rotation: Vector3?)->();
	update: (self: object, dt: number)->();
	set_target: (self: object, target: CFrame, is_snapped: boolean?)->();
	
	get_position: (self: object)->CFrame;
	set_position: (self: object, CFrame)->();
	
	get_velocity: (self: object)-> CFrame;
	set_velocity: (self: object, CFrame)->();
	set_velocity_from_pair: (self: object, position: Vector3, rotation: quaternion)->();
	
	get_target: (self: object) -> (CFrame);
	
	get_damper: (self: object)->(number, number);
	set_damper: (self: object, number, number)->();
	
	get_speed: (self: object)->(number, number);
	set_speed: (self: object, number, number)->();

	get_clock: (self: object)->(clock, clock);
	set_clock: (self: object, clock, clock)->();
}

module = {}
q_from_cframe = Quaternion.fromCFrame
compose = Dash.compose
pi = math.pi
pi2 = pi * 2

function module.new(init: CFrame?, clock: clock?): object
	local i = init or CFrame.identity
	local clock = clock or module.default_clock
	
	local self = Object.simple.from.struct({
		position_spring = NevermoreSpring.new(i.Position, clock);
		rotation_spring = QuaternionSpring.new(q_from_cframe(i), nil, nil, clock)
	}, module)
	
	self.rotation_spring.d = self.position_spring.d
	self.rotation_spring.s = self.position_spring.s
	
	return self
end

function module.default_clock() return workspace.DistributedGameTime end

function module.impulse(self: object, position: Vector3, rotation: Vector3)
	self.position_spring:Impulse(position or Vector3.zero)
	self.rotation_spring:Impulse(rotation or Vector3.zero)
end

function module.update(self: object, dt: number)
	self.position_spring:TimeSkip(dt)
	self.rotation_spring:TimeSkip(dt)
end

function module.set_target(self: object, value: CFrame, is_snapped: boolean?)
	self.position_spring:SetTarget(value.Position, is_snapped)
	
	local rotation = self.rotation_spring
	local q = q_from_cframe(value)
	
	if is_snapped then
		local now = rotation.Clock()
		rotation._position = q
		rotation._velocity = Quaternion.zero
		rotation._target = q;
		rotation._time0 = now
	else
		self.rotation_spring.t = q
	end
	
	-- self.rotation_spring:SetTarget(q_from_cframe(value), is_snapped)
end

function get_pair(self: object, i: string)
	return self.position_spring[i], self.rotation_spring[i]
end

function get_pair_f(i: string)
	return function(self: object)
		return get_pair(self, i)
	end
end

function get_cf_from_pair(self: object, i: string)
	local p: Vector3, r: quaternion = get_pair(self, i)
	return r:ToCFrame(p)
end

function get_cf_from_pair_f(i: string)
	return function(self: object)
		return get_cf_from_pair(self, i)
	end
end

function set_pair(self: object, i: string, positional_value, rotational_value)
	if positional_value then
		self.position_spring[i] = positional_value
	end
	
	if rotational_value then
		self.rotation_spring[i] = rotational_value
	end
end

function set_pair_f(i: string)
	return function(self: object, p, r)
		return set_pair(self, i, p, r)
	end
end

function set_cf_from_pair(self: object, i: string, cf: CFrame)
	local position, rotation = cf.Position, q_from_cframe(cf)
	set_pair(self, i, position, rotation)
end

function set_cf_from_pair_f(i: string)
	return function(self: object, cf: CFrame)
		set_cf_from_pair(self, i, cf)
	end
end

module.get_position = get_cf_from_pair_f('Position')
module.set_position = set_cf_from_pair_f('Position')
module.get_velocity = get_cf_from_pair_f('Velocity')
module.set_velocity = set_cf_from_pair_f('Velocity')
module.set_velocity_from_pair = set_pair_f('Velocity')
module.get_target = get_cf_from_pair_f('Target')
module.get_damper = get_pair_f('Damper')
module.set_damper = set_pair_f('Damper')
module.get_speed = get_pair_f('Speed')
module.set_speed = set_pair_f('Speed')
module.get_clock = get_pair_f('Clock')
module.set_clock = set_pair_f('Clock')

module.__index = module

return module
