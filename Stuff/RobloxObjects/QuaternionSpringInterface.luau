--[[
	https://github.com/daymxn/LuaQuaternion/blob/main/src/QuaternionSpring.lua
	
	Interface for quaternion spring due failing to fetch the type
]]

local Quaternion = require('./Quaternion')

export type quaternion = Quaternion.Quaternion

export type spring = {
	Impulse: (self: spring, velocity: Vector3) -> (),
	TimeSkip: (self: spring, delta: number) -> (),
	
	Position: quaternion,
	p: quaternion,
	Velocity: Vector3,
	v: Vector3,
	Target: quaternion,
	t: quaternion,
	Damping: number,
	d: number,
	Speed: number,
	s: number,
	Clock: () -> number,
}

export type module = {
	new: (initial: quaternion, damping: number, speed: number, clock: () -> number) -> spring,
	Reset: (target: quaternion?) -> (),
}

local module = {}

function module.get(): module
	return require('./@daymxn>QuaternionSpring')
end

return module
