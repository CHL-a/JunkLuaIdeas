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

type __updatableSpring<A> = {
	canUpdate: boolean;
	shouldDisconnect: boolean;
	update: (self:__updatableSpring<A>, delta: number) -> nil;
} & spring<A>

local module = {}

module.workspaceRuntime = function()return workspace.DistributedGameTime end

module.update = function<A>(self:__spring<A>, delta: number)self:TimeSkip(delta)end

module.addUpdateMethod = function<A>(self: __spring<A>)
	rawset(self, 'update', module.update)
	rawset(self, 'canUpdate', true)
	rawset(self, 'shouldDisconnect', false)
end

return module
