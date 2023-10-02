-- Interface for:
-- https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Physics/Spring.lua

type __spring<A> = {
	-- values
	-- position
	Value: A;
	Position: A;
	p: A;
	
	-- velocity
	Velocity: A;
	v: A;
	
	-- target
	Target: A;
	t: A;
	
	-- damper
	Damper: number;
	d: number;
	
	-- speed
	Speed: number;
	s: number;
	
	-- clock method
	Clock: () -> number;
	
	-- methods
	Impulse: (self:__spring<A>, velocity: A) -> nil;
	TimeSkip: (self:__spring<A>, delta: number) -> nil;
}

export type spring<A> = __spring<A>

type __updatableSpring<A> = {
	canUpdate: boolean;
	shouldDisconnect: boolean;
	update: (self:__updatableSpring<A>, delta: number) -> nil;
} & spring<A>
export type updatableSpring<A> = __updatableSpring<A>

local disguise = require(script.Parent.LuaUTypes).disguise
local W = require(script.Parent.LambertW)
local module = {}

local e = math.exp(1)
module.e = e

module.workspaceRuntime = function()return workspace.DistributedGameTime end

module.update = function<A>(self:__spring<A>, delta: number)self:TimeSkip(delta)end

module.getBlankNumberSpring = function(): __spring<number>
	if disguise(module).numberSpring then
		return disguise(module).numberSpring;
	end
	
	disguise(module).numberSpring = 
		require(script.Parent.NevermoreSpring).new(0, module.workspaceRuntime)
	
	return module.getBlankNumberSpring()
end

--[[
	mutates spring such that it will jolt upward to reach a peak when target = 0 and damp = 1
]]
module.peakify_from_n_spring = function(self:__spring<number>, target: number)
	local p = self.p
	local s = self.s
	
	-- solve for t1 to get the point where p - 0 
	-- obtained by checking the position function and finding t when pa(t) = 0
	local t1 = -p / (p * s + self.v)
	
	-- rewind time to put p0 at 0 and v based on a known idea of velocity and target
	self:TimeSkip(t1)
	self.v = s * e * disguise(target)
	
	-- resume time to an equivilent elevation by finding another t, let be t2
	local t2 = -W(-p / e) / s
	self:TimeSkip(t2)
end

module.update_from_components = function<A>(
	p0: A, 
	v0: A, 
	p1: A,
	d: number, 
	s: number,
	delta_t: number)

	local t = s*(delta_t)
	local d2 = d*d

	local h, si, co
	if d2 < 1 then
		h = math.sqrt(1 - d2)
		local ep = math.exp(-d*t)/h
		co, si = ep*math.cos(h*t), ep*math.sin(h*t)
	elseif d2 == 1 then 
		h = 1
		local ep = math.exp(-d*t)/h
		co, si = ep, ep*t
	else
		h = math.sqrt(d2 - 1)
		local u = math.exp((-d + h)*t)/(2*h)
		local v = math.exp((-d - h)*t)/(2*h)
		co, si = u + v, u - v
	end

	local a0 = h*co + d*si
	local a1 = 1 - (h*co + d*si)
	local a2 = si/s

	local b0 = -s*si
	local b1 = s*si
	local b2 = h*co - d*si

	return
		a0*p0 + a1*p1 + a2*v0,
		b0*p0 + b1*p1 + b2*v0
end

function initBlankPeakify(s:number)
	local blank: __spring<number> = module.getBlankNumberSpring()
	blank.s = s
	blank.d = 1;
	blank.t = 0
end

function mutatePVect<A>(spring: __spring<A>, axis: string, target: A)
	local blank: __spring<number> = module.getBlankNumberSpring()

	blank.v = disguise(spring).v[axis]
	blank.p = disguise(spring).p[axis]
	module.peakify_from_n_spring(blank, disguise(target)[axis])
	
	return blank.v
end

module.peakifyVector2 = function(self:__spring<Vector2>, target:Vector2)
	initBlankPeakify(self.s)
	
	self.Velocity = Vector2.new(
		mutatePVect(self, 'X', target),
		mutatePVect(self, 'Y', target)
	)
end

module.peakifyVector3 = function(self:__spring<Vector3>, target: Vector3)
	initBlankPeakify(self.s)
	
	self.Velocity = Vector3.new(
		mutatePVect(self, 'X', target),
		mutatePVect(self, 'Y', target),
		mutatePVect(self, 'Z', target)
	)
end


module.addUpdateMethod = function<A>(self: __spring<A>)
	rawset(self, 'update', module.update)
	rawset(self, 'canUpdate', true)
	rawset(self, 'shouldDisconnect', false)
	
	return self
end

return module
