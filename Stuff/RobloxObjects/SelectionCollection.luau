--// TYPES
local Switch = require('./@CHL>Switch')
local Dash = require('./@CHL>DashSingular')

export type object<A> = {
	switchCollection: Dash.Map<A,Switch.object>;

	addSwitch: (self: object<A>, i: A, v: Switch.object) -> ();
	getSwitched: (self: object<A>) -> Dash.Array<A>;
	clearSwitches: (self: object<A>) -> ();
	turnAllButOneOff: (self: object<A>, one: Switch.object) -> ();
}

--// MAIN
local module = {}
local disguise = require('./LuaUTypes').disguise
local compose = Dash.compose

module.__index = module

function module.new<A>(): object<A>
	local self: object<A> = disguise(setmetatable({}, module))
	
	self.switchCollection = {}
	
	return self
end

function module.addSwitch<A>(self: object<A>, i: A, v: Switch.object)
	self.switchCollection[i] = v
end

function __getSwitched<A>(i: A, v: Switch.object)return v.isOn and i or nil;end

module.getSwitched = compose(
	function<A>(self: object<A>)return self.switchCollection, __getSwitched end,
	Dash.collectArray
)

module.clearSwitches = compose(
	function<A>(self:object<A>)return self.switchCollection end,
	table.clear
)

function module.turnAllButOneOff<A>(self: object<A>, i: A)
	for j, v in next, self.switchCollection do
		v:flick(j == i)
	end
end


return module
