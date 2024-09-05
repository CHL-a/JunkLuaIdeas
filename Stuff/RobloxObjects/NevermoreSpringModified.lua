-- a version of NevermoreSpring that is considered mutable
-- https://github.com/Quenty/NevermoreEngine/blob/main/src/spring/src/Shared/Spring.lua#L98

-- type
local Objects = script.Parent

local Object = require(Objects.Object)

local SpringInterface = require(Objects["@CHL/SpringInterfaces"])
local NevermoreSpring = require(Objects.NevermoreSpring)
local Class = require(Objects.Class)
local RuntimeUpdater = require(Objects.RuntimeUpdater)

export type object<A> = {
	-- is in spring
	SetTarget: (self: object<A>, A, boolean)->();
} & Class.subclass<SpringInterface.nevermore<A>>
  & Object.object_inheritance
  & RuntimeUpdater.updatable

-- main
local module = {}

disguise = require(Objects.LuaUTypes).disguise

function module.new<A>(p: A, runtimer: (()->number)?): object<A>
	runtimer = runtimer or module.defaults.runtimer
	
	local old = NevermoreSpring.new(p, runtimer)
	setmetatable(old, nil)
	local self: object<A> = Object.from.rawStruct(old):__inherit(module)
	self.canUpdate = true
	self.shouldDisconnect = false
	
	return self
end

function module.update<A>(self: object<A>, dt: number)return self:TimeSkip(dt)end

function module.__index<A>(self: object<A>, i: string)
	local _s = disguise(self)
	if module[i] then return module[i]
	elseif i == "Value" or i == "Position" or i == "p" then
		local position = _s:_positionVelocity(_s._clock())
		return position
	elseif i == "Velocity" or i == "v" then
		local _, velocity = _s:_positionVelocity(_s._clock())
		return velocity
	elseif i == "Target" or i == "t" then return _s._target
	elseif i == "Damper" or i == "d" then return _s._damper
	elseif i == "Speed" or i == "s" then return _s._speed
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
	
	if i == "Value" or i == "Position" or i == "p" then
		_s._position0 = v
	elseif i == "Velocity" or i == "v" then
		_s._velocity0 = v
	elseif i == "Target" or i == "t" then
		_s._target = v
	elseif i == "Damper" or i == "d" then
		_s._damper = v
	elseif i == "Speed" or i == "s" then
		_s._speed = math.max(0, disguise(v))
	elseif i == "Clock" then
		_s._clock = v
		_s._time0 = disguise(v)()
	else
		rawset(_s, i, v)
	end
end

module.defaults = {}
module.defaults.runtimer = function(): number return workspace.DistributedGameTime end
module.Impulse = NevermoreSpring.Impulse
module.TimeSkip = NevermoreSpring.TimeSkip
module._positionVelocity = NevermoreSpring._positionVelocity
module.SetTarget = NevermoreSpring.SetTarget
module.className = '@CHL/Spring'


return module
