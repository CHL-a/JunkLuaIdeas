--[[
	From: https://github.com/ZachCurtis/EasyBullet/tree/main
--]]

local EasyBulletModule = script.Parent.EasyBullet
local BulletModule = EasyBulletModule.Bullet

local Bullet = require(BulletModule)
local Signal = require(script.Parent.SignalInterface)

type __bulletData<__data> = __data & {
	HitVelocity: Vector3;
	BulletId: string;
} & Bullet.BulletData
export type bulletData<data> = __bulletData<data>

type __EasyBulletSettings<data> = {
	BulletData: __bulletData<data>?;
} & Bullet.EasyBulletSettings
export type EasyBulletSettings<data> = __EasyBulletSettings<data>

type __object<data> = {
	--// methods
	FireBullet: (
		self: __object<data>, 
		position: Vector3,
		velocity: Vector3,
		__EasyBulletSettings<data>?) -> nil;
	BindCustomCast: (
		self: __object<data>,
		fnBind: (
			shooter: Player?,
			lastFramePosition: Vector3,
			thisFramePosition: Vector3,
			elapsedTime: number,
			bulletData: __bulletData<data>?
			) -> RaycastResult
		) -> nil;
	BindShouldFire: (
		self: __object<data>,
		fnBind: (
			shooter: Player?,
			barrelPosition: Vector3,
			velocity: Vector3,
			ping: number,
			__EasyBulletSettings<data>?
			) -> boolean
		) -> nil;
	
	--// signals
	BulletHit: Signal.object<
		Player, 
		RaycastResult, 
		__bulletData<data>>;
	BulletHitHumanoid: Signal.object<
		Player, 
		RaycastResult, 
		Humanoid, 
		__bulletData<data>>;
	BulletUpdated: Signal.object<Vector3, Vector3, __bulletData<data>>
}
export type object<data> = __object<data>;

type __module = {
	new: <data>(__EasyBulletSettings<data>) -> __object<data>;
}
export type module = __module

return true
