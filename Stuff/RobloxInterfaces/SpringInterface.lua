-- Interface for:
-- https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Physics/Spring.lua
export type nevermore<A> = {
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
	Impulse: (self:nevermore<A>, velocity: A) -> ();
	TimeSkip: (self:nevermore<A>, delta: number) -> ();
}
