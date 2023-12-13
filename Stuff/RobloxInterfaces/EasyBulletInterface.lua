--[[
	From: https://github.com/ZachCurtis/EasyBullet/tree/main
--]]

local EasyBulletModule = script.Parent.EasyBullet
local BulletModule = EasyBulletModule.Bullet

local Bullet = require(BulletModule)
local Signal = require(script.Parent.SignalInterface)

type __EasyBulletSettings = Bullet.EasyBulletSettings
export type EasyBulletSettings = __EasyBulletSettings

type __object = {
	--// methods
	FireBullet: (
		self: __object, 
		position: Vector3,
		velocity: Vector3,
		__EasyBulletSettings?) -> nil;
	BindCustomCast: (
		self: __object,
		fnBind: (
			shooter: Player?,
			lastFramePosition: Vector3,
			thisFramePosition: Vector3,
			elapsedTime: number,
			bulletData: {[string]: any}
			) -> RaycastResult
		) -> nil;
	BindShouldFire: (
		self: __object,
		fnBind: (
			shooter: Player?,
			barrelPosition: Vector3,
			velocity: Vector3,
			ping: number,
			__EasyBulletSettings?
			) -> boolean
		) -> nil;
	
	--// signals
	BulletHit: Signal.object<
		Player, 
		RaycastResult, 
		{[string]: any} | {HitVelocity: Vector3}>;
	BulletHitHumanoid: Signal.object<
		Player, 
		RaycastResult, 
		Humanoid, 
		{[string]: any} | {HitVelocity: Vector3}>;
	BulletUpdated: Signal.object<Vector3, Vector3, {[string]: any}>
}
export type object = __object;




type __module = {
	new: (__EasyBulletSettings) -> __object;
}
export type module = __module

return true
