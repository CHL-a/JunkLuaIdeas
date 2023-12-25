--// TYPES
local Objects = script.Parent
local Class = require(Objects.Class)

-- base
type __object = {
	script: LocalScript;
	playEmoteRemote: BindableFunction;

	findSetting: (self:__object, string) -> ValueBase?;
	getSetting: (self:__object, string) -> ValueBase;
	playRemote: (self: __object, emoteName: string) -> (boolean?, AnimationTrack?) | 
	(self: __object, custom: Animation) -> (boolean?, AnimationTrack?);
}
export type object = __object

-- default
type __default = {
	findSetting: (self:__object, __default_setting_index) -> ValueBase?;
	getSetting: (self:__object, __default_setting_index) -> ValueBase;

	setScaleDampeningPercent: (self:__object, number) -> nil;
	getScaleDampeningPercent: (self: __object) -> number;

	getAnimations: (self:__object, __animation_default_index) -> {Animation};
	setAnimations: (self:__object, __animation_default_index, ...Animation | string ) -> nil;
} & Class.subclass<__object>

type __animation_default_index = 'cheer' | 'climb' | 'dance' | 
'dance2' | 'dance3' | 'fall' | 'idle' | 'jump' | 'laugh' | 'mood' | 'point' | 'run' |
'sit' | 'swim' | 'swimidle' | 'toollunge' | 'toolnone' | 'toolslash' | 'walk' | 'wave'

type __default_setting_index = 'ScaleDampeningPercent' | __animation_default_index
export type default_setting_index = __default_setting_index

-- strafe
type __strafe = {
	findSetting: (self:__object, __strafe_setting_index) -> ValueBase?;
	getSetting: (self:__object, __strafe_setting_index) -> ValueBase;

	getAnimations: (self:__object, __animation_strafe_settings) -> {Animation};
	setAnimations: (self:__object, __animation_strafe_settings, ...Animation | string ) -> nil;
} & __default

type __animation_strafe_settings = __animation_default_index | 'runBack' | 
'runBackwardLeft' | 'runBackwardRight' | 'runForwardLeft' | 'runForwardRight' | 
'runLeft' | 'runLeft2' | 'runRight' | 'runRight2' | 'walkBack' | 'walkBackwardLeft' |
'walkBackwardRight' | 'walkForwardLeft' | 'walkForwardRight' | 'walkLeft' | 
'walkLeft2' | 'walkRight' | 'walkRight2'
export type animation_strafe_settings = __animation_strafe_settings

type __strafe_setting_index = __default_setting_index | __animation_strafe_settings
export type strafe_setting_index = __strafe_setting_index

--// MAIN
local module = {}
local disguise = require(Objects.LuaUTypes).disguise

--// BASE
local base = {}
base.__index = base

function base.new(lS: LocalScript)
	local self: __object = disguise(setmetatable({}, base))

	self.script = lS
	self.playEmoteRemote = disguise(lS:WaitForChild('PlayEmote'))

	return self
end

base.findSetting = function(self:__object, s: string)
	return self.script:FindFirstChild(s)
end

base.getSetting = function(self:__object, s: string)return assert(self:findSetting(s))end
base.playRemote = function(self:__object, arg)return self.playEmoteRemote:Invoke(arg)end

module.base = base

--// DEFAULT
local default = {}
default.__index = default

function default.new(lS: LocalScript)
	local self: __default = disguise(Class.inherit(base.new(lS), default))

	return self
end

default.setScaleDampeningPercent = function(self:__default, n: number)
	disguise(self:getSetting('ScaleDampeningPercent')).Value = n
end

default.getScaleDampeningPercent = function(self:__default)
	return disguise(self:getSetting('ScaleDampeningPercent')).Value
end

default.getAnimations = function(self:__default, name: __default_setting_index)
	return self:getSetting(name):GetChildren()
end

default.setAnimations = function(
	self:__default, 
	name:__default_setting_index, 
	...: Animation | string)
	local value = self:getSetting(name)
	value:ClearAllChildren()

	for i = 1, select('#', ...) do
		local anim: Animation = select(i, ...)

		if type(anim) == 'string' then
			local tempAnimation = Instance.new('Animation')
			tempAnimation.AnimationId = anim

			anim = tempAnimation
		end

		anim.Parent = value
	end
end

module.default = default

--// STRAFE
local strafe = {}

function strafe.new(lS: LocalScript)
	return default.new(lS) :: __strafe
end

module.strafe = strafe

return module
