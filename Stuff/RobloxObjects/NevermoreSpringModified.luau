--[[
	A version of spring where the math is derived from NevermoreEngine
	
	made because the nevermore engine preemptively uses update regardless of the actual time it's in

	https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua#L98
]]
export type object<T> = {
	position: T;
	velocity: T;
	target: T;
	damper: number;
	speed: number;
	enabled: boolean;
	
	impulse: (self: object<T>, velocity: T) -> ();
	time_skip: (self: object<T>, dt: number) -> (T, T);
	update: (self: object<T>, dt: number) -> ();
}

-- type
local Class = require('./Class')
local Object = require('./Object')

-- main
local module = {}

disguise = require('./LuaUTypes').disguise

Class.make_proper_class(module, '@CHL>Spring')

function module.new<T>(position_0: T): object<T>
	
	local self: object<T> = Object.simple.new(module)
	
	self.position = position_0
	self.velocity = 0 * position_0
	self.target = position_0
	self.damper = 1
	self.speed = 1
	self.enabled = true
	
	return self
end

function module.impulse<T>(self: object<T>, velocity: T)
	self.velocity += velocity
end

--[[
	the main state fetch function
]]
function module.time_skip<T>(self: object<T>, dt: number)
	local p = self.position
	local v = self.velocity
	local t = self.target
	local d = self.damper
	local s = self.speed
	local d2 = d * d
	
	dt *= s
	
	local h, si, co
	if d2 < 1 then
		h = math.sqrt(1 - d2)
		local ep = math.exp(-d * dt) / h
		co, si = ep * math.cos(h * dt), ep * math.sin(h * dt)
	elseif d2 == 1 then
		h = 1
		local ep = math.exp(-d * dt) / h
		co, si = ep, ep * dt
	else
		h = math.sqrt(d2 - 1)
		local u = math.exp((-d + h) * dt) / (2 * h)
		local v = math.exp((-d - h) * dt) / (2 * h)
		co, si = u + v, u - v
	end
	
	local a0: number = h * co + d * si
	local a1: number = 1 - (h * co + d * si)
	local a2: number = si / s
	
	local b0: number = -s * si
	local b1: number = s * si
	local b2: number = h * co - d * si
	
	return a0 * p + a1 * t + a2 * v,
	       b0 * p + b1 * t + b2 * v
end

function module.update<T>(self: object<T>, dt: number)
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

return module
