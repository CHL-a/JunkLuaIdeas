--// TYPES
local Objects = script.Parent
local Switch = require(Objects["@CHL/Switch"])
local Dash = require(Objects["@CHL/DashSingular"])

type __object<A> = {
	switchCollection: Dash.Map<A,Switch.object>;
	
	addSwitch: (self: __object<A>, i: A, v: Switch.object) -> nil;
	getSwitched: (self: __object<A>) -> Dash.Array<A>;
	clearSwitches: (self:__object<A>) -> nil;
}
export type object<A> = __object<A>

--// MAIN
local module = {}
local disguise = require(Objects.LuaUTypes).disguise
local compose = Dash.compose

module.__index = module

function module.new<A>()
	local self: __object<A> = disguise(setmetatable({}, module))
	
	self.switchCollection = {}
	
	return self
end

module.addSwitch = function<A>(self: __object<A>, i: A, v: Switch.object)
	self.switchCollection[i] = v
end

function __getSwitched<A>(i: A, v: Switch.object)return v.isOn and i or nil;end

module.getSwitched = compose(
	function<A>(self: __object<A>)return self.switchCollection, __getSwitched end,
	Dash.collectArray
)

module.clearSwitches = compose(
	function<A>(self:__object<A>)return self.switchCollection end,
	table.clear
)



return module
