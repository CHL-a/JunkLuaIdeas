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
	target: A;
	t: A;
	
	-- damper
	damper: number;
	d: number;
	
	-- speed
	speed: number;
	s: number;
	
	-- clock method
	Clock: () -> number;
	
	-- methods
	Impulse: (self:__spring<A>, velocity: A) -> nil;
	TimeSkip: (self:__spring<A>, delta: number) -> nil;
}

export type spring<A> = __spring<A>
return true
