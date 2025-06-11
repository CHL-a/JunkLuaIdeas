-- a version of NevermoreSpring that is considered mutable
-- https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua#L98

-- type
local Object = require('./Object')
local SpringInterface = require('./@CHL>SpringInterfaces')
local NevermoreSpring = require('./NevermoreSpring')
local Class = require('./Class')
local RuntimeUpdater = require('./@CHL>RuntimeUpdater')

export type clock_function = ()->number;

export type object<A> = {
	-- is in spring
	SetTarget: (self: object<A>, A, boolean)->();
} & Class.subclass<SpringInterface.nevermore<A>>
  & Object.object_inheritance
  & RuntimeUpdater.updatable

-- main
local module = {}
local LuaUTypes = require('./LuaUTypes')

module.from = {}
disguise = LuaUTypes.disguise

function module.new<A>(p: A, runtimer: clock_function?): object<A>
	runtimer = runtimer or module.defaults.runtimer
	
	local old = NevermoreSpring.new(p, runtimer)
	setmetatable(old, nil)
	local self: object<A> = Object.from.rawStruct(old):__inherit(module)
	self.canUpdate = true
	self.shouldDisconnect = false
	
	return self
end

function module.from.values<A>(
	position0: A,
	position1: A?,
	velocity: A?,
	damper: number?,
	speed: number?,
	clock: clock_function?): object<A>
	local self = module.new(position0, clock)
	
	if position1 then self.t = position1 end
	if velocity then self.v = velocity end
	if damper then self.d = damper end
	if speed then self.s = speed end
	return self
end

function module.__index<A>(self: object<A>, i: string)
	local _s = disguise(self)
	local alias = module.property_aliases[i]
	
	if module[i] then return module[i]
	elseif alias then return _s:__index(alias)
	elseif i == "Position" then
		local position = _s:_positionVelocity(_s._clock())
		return position
	elseif i == "Velocity" then
		local _, velocity = _s:_positionVelocity(_s._clock())
		return velocity
	elseif i == "Target" then return _s._target
	elseif i == "Damper" then return _s._damper
	elseif i == "Speed" then return _s._speed
	elseif i == "Clock" then return _s._clock
	else return _s.__super[i]end
end

function module.__newindex<A, B>(self: object<A>, i: string, v: B)
	local _s = disguise(self)
	local now = _s._clock()
	
	local p, ve = _s:_positionVelocity(now)
	_s._position0 = p
	_s._velocity0 = ve
	_s._time0 = now
	
	local alias = module.property_aliases[i]
	if alias then
		return _s:__newindex(i, v)
	elseif i == "Position" then
		_s._position0 = v
	elseif i == "Velocity" then
		_s._velocity0 = v
	elseif i == "Target" then
		_s._target = v
	elseif i == "Damper" then
		_s._damper = v
	elseif i == "Speed" then
		_s._speed = math.max(0, disguise(v))
	elseif i == "Clock" then
		_s._clock = v
		_s._time0 = disguise(v)()
	else
		rawset(_s, i, v)
	end
end

module.property_aliases = {
	p = 'Position';
	Value = 'Position';
	v = 'Velocity';
	t = 'Target';
	d = 'Damper';
	s = 'Speed';
	
}
module.defaults = {}
module.defaults.runtimer = function(): number return workspace.DistributedGameTime end
module.Impulse = NevermoreSpring.Impulse
module.TimeSkip = NevermoreSpring.TimeSkip
module.update = module.TimeSkip
module._positionVelocity = NevermoreSpring._positionVelocity
module.SetTarget = NevermoreSpring.SetTarget
module.className = '@CHL>Spring'


return module
