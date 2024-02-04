--// TYPES
local Objects = script.Parent
local Switch = require(Objects["@CHL/Switch"])
local Set = require(Objects["@CHL/Set"])
local EventPackage = require(Objects.EventPackage)
local Class = require(Objects.Class)
local Dash = require(Objects["@CHL/DashSingular"])

type switch = Switch.object;
type map<I,V> = Dash.Map<I,V>

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise
compose = Dash.compose

--#######################################################################################
--#######################################################################################
--#######################################################################################

export type radio = {
	selected: switch;
	switches: Set.simple<switch>;
	
	selectSwitch: (self: radio, switch) -> nil;
	
	selectionChanged: EventPackage.event<switch, switch>;
	__selectionChanged: EventPackage.package<switch, switch>;
}

-- default
radio = {}
radio.__index = radio

function radio.fromSet(sw: Set.simple<switch>): radio
	-- pre
	local first = next(sw)
	assert(first ~= nil, 'Attempting to construct a radio with a null set.')
	
	sw = table.clone(sw)
	
	-- main
	local self: radio = disguise(setmetatable({}, radio))
	self.switches = sw;
	
	self.__selectionChanged = EventPackage.new()
	self.selectionChanged = self.__selectionChanged.event
	
	self:selectSwitch(first)
	
	return self
end

radio.fromArray = compose(Set.simple.from.arrays, radio.fromSet)
	:: ({switch}) -> radio;

radio.selectSwitch = function(self: radio, s: switch)
	if self.selected then
		self.selected:flick(false)
	end
	
	s:flick(true)
	self.selected = s
end

--#######################################################################################
--#######################################################################################
--#######################################################################################

-- switch referral
export type switchReferral<A> = {
	value: A
} & Class.subclass<switch>

--#######################################################################################
--#######################################################################################
--#######################################################################################

export type radioValue<A> = {
	selected: switchReferral<A>;
	switches: Set.simple<switchReferral<A>>;
	referrals: map<A, switchReferral<A>>;
	
	selectReferral: (self: radioValue<A>, a: A) -> nil;
	
	__selectionChanged: EventPackage.package<switchReferral<A>, switchReferral<A>>;
	selectionChanged: EventPackage.event<switchReferral<A>, switchReferral<A>>;
} & Class.subclass<radio>

radioValue = {}
radioValue.__index = radioValue

function referralCollect<A>(s: switchReferral<A>)return s.value, s;end

function radioValue.fromSet<A>(sw: Set.simple<switchReferral<A>>): radioValue<A>
	local self: radioValue<A> = Class.inherit(radio.fromSet(sw), radioValue)
	
	self.referrals = Dash.collect(self.switches, referralCollect)
	
	return self
end

radioValue.fromArray = compose(Set.simple.from.arrays, radioValue.fromSet)
	:: <A>({switchReferral<A>}) -> radioValue<A>

radioValue.selectReferral = function<A>(self:radioValue<A>, ref: A)
	self:selectSwitch(self.referrals[ref])
end

--#######################################################################################
--#######################################################################################
--#######################################################################################

module.radio = radio
module.radioValue = radioValue;

return module
