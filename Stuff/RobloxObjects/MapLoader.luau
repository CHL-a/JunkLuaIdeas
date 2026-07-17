local module = {}

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

local LuaUTypes = require('./LuaUTypes')

disguise = LuaUTypes.disguise
empty = LuaUTypes.empty

module.void = disguise() :: Instance

function module.get_void(): Instance return assert(module.void, '@CHL>MapLoader: missing void container') end

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- defines as any map thats sufficiently large enough or anything that invokes a new map (aptly called universe, not necessarily as large as a universe itself)
universe_loader = {}

universe_loader.space = workspace

function universe_loader.add_universe(arg: Instance)
	local container = module.get_void()
	
	if container:FindFirstChild(arg.Name) then
		warn('Universe already exists')
		return
	end
	
	arg:SetAttribute('__is_map', true)
	arg.Parent = container
end

function universe_loader.load(arg: string | Instance)
	local container = module.get_void()
	local universe = typeof(arg) == 'Instance' and arg or container:FindFirstChild(arg)
	
	assert(universe and universe.Parent == container, 'Universe non-existant or is not under container')
	
	universe.Parent = universe_loader.space
end

function universe_loader.unload(arg: string)
	local container = module.get_void()
	local space = universe_loader.space
	local universe = typeof(arg) == 'Instance' and arg or universe_loader.space:FindFirstChild(arg)
	
	assert(universe and universe.Parent == space, 'Universe non-existant or is not under space')
	
	if not universe:GetAttribute('__is_map') then
		warn('Attempted to unload a non-universe')
		return
	end
	
	universe.Parent = container
end

function universe_loader.is_loaded(arg: string | Instance): boolean
	local space = universe_loader.space
	
	return typeof(arg) == 'Instance' and arg:IsDescendantOf(space) or space:FindFirstChild(arg) ~= nil
end

module.universe_loader = universe_loader

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- defines as any part of the map where a loading trigger can be invoked by entering to trigger a map load or unload

export type continent_loader_base = {
	instances: {Instance};
	space: Instance;
	
	load: (self: continent_loader_base) -> (),
	unload: (self: continent_loader_base) -> (),
	detach: (self: continent_loader_base) -> (),
	destroy: (self: continent_loader_base) -> (),
}

local Hierarchy = require('./@CHL>Hierarchy')

continent_loader = {}

function continent_loader.from_part_format_1(part: BasePart, observer: observer, space: Instance?): continent_loader_base
	if not part:GetAttribute('__is_loading_trigger') then
		warn(`Attempted to load from a non-loading trigger: {part:GetFullName()}`)
		return
	end
	
	if not part.Anchored then warn(`Attempting to load from an unanchored loading trigger: {part:GetFullName()}`) end
	if part.CanCollide then warn(`Attempting to load from a collidable loading trigger: {part:GetFullName()}`) end
	if part.CanQuery then warn(`Attempting to load from a queryable loading trigger: {part:GetFullName()}`) end
	
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	
	local lt_referral = part:GetAttribute('lt_referral')
	
	if not lt_referral then
		warn(`Attempted to load from a loading trigger without a valid lt_referral: {part:GetFullName()}`)
		return
	end
	
	local lt_type = part:GetAttribute('lt_type')
	
	if not lt_type then
		warn(`Attempted to load from a loading trigger without a valid lt_type: {part:GetFullName()}`)
		return
	end
	
	local referral = Hierarchy.invoke_query({
		query = lt_referral;
		root_instance = game;
		current_working_instance = part;
		observer = observer;
	})
	
	if not referral then
		warn(`Attempted to load from a loading trigger with an invalid referral: {part:GetFullName()}, {lt_referral}`)
		return
	end
	
	local result;
	local arg: continent_loader_arg = {}
	arg.part = part
	arg.instances = {referral}
	arg.space = space or workspace -- ?
	arg.observer = observer
	
	if lt_type == 'entrance' then
		result = continent_loader.entrance.from.part(arg)
	elseif lt_type == 'exit' then
		result = continent_loader.exit.from.part(arg)
	end
	
	if not result then
		warn(`Attempted to load from a loading trigger with an invalid type: {part:GetFullName()}, {lt_type}`)
	end
	
	return result
end

module.continent_loader = continent_loader

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- non functional abstract class
continent_loader.base = {}

function continent_loader.base.new(instances: {Instance}, space: Instance): continent_loader_base
	local self = {}
	
	self.instances = instances
	self.space = space
	
	return self
end

function continent_loader.base.load(self: continent_loader_base) 
	local space = self.space
	
	assert(space, 'missing space instance')
	
	for _, inst in self.instances do
		inst.Parent = space
	end
end

function continent_loader.base.unload(self: continent_loader_base)
	local void = module.get_void()
	
	for _, inst in self.instances do
		inst.Parent = void
	end
end

function continent_loader.base.detach(self: continent_loader_base)
	table.clear(self.instances)
end

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- class responsible for exclusively loading a continent when invoking a zone listener
local Zone = require('./QuickZone')
local Class = require('./Class')
local Object = require('./Object')

type observer = Zone.Observer<Player>
type zone = Zone.Zone

export type continent_loader_entrance = {
	observer: observer,
	zones: {zone};
	
	set_observer: (self: continent_loader_entrance, observer: observer) -> (),
	set_zones: (self: continent_loader_entrance, zones: {zone}) -> (),
	destroy_observation: (self: continent_loader_entrance) -> (),
} & continent_loader_base

continent_loader.entrance = {}
continent_loader.entrance.from = {}

export type continent_loader_arg = {
	observer: observer;
	instances: {Instance};
	space: Instance;
	zones: {zone};
}

function continent_loader.entrance.new(arg: continent_loader_arg): continent_loader_entrance
	local self: continent_loader_entrance = continent_loader.base.new(arg.instances, arg.space)
	
	setmetatable(disguise(self), continent_loader.entrance)
	
	self.destroy_observation = empty
	self:set_observer(arg.observer)
	self:set_zones(arg.zones)
	
	return self
end

function continent_loader.entrance.set_observer(self: continent_loader_entrance, observer: observer)
	if self.observer and self.zones then
		for _, zone in self.zones do
			self.observer:detach(zone)
		end
		
		self:destroy_observation()
	end
	
	self.observer = observer
	
	if observer then
		self.destroy_observation = observer:onPlayerEnter(function(item, zone)
			if not table.find(self.zones, zone) then
				return
			end
			self:load()
		end)
	end
end

function continent_loader.entrance.set_zones(self: continent_loader_entrance, zones: {zone})
	if self.observer and self.zones then
		for _, zone in self.zones do
			self.observer:detach(zone)
		end
	end
	
	self.zones = zones
	
	for _, zone in zones do
		self.observer:attach(zone)
	end
end

function continent_loader.entrance.detach(self: continent_loader_entrance)
	continent_loader.base.detach(self)
	
	if self.observer then
		self:destroy_observation()
		self.observer = nil
	end
	
	if self.zones then
		self:set_zones{}
	end
end

function continent_loader.entrance.from.part(arg: continent_loader_arg & {part: BasePart})
	local zone = Zone.Zone.fromPart(arg.part)
	
	arg.zones = {zone}
	
	return continent_loader.entrance.new(arg)
end

continent_loader.entrance.unload = continent_loader.base.unload
continent_loader.entrance.load = continent_loader.base.load
continent_loader.entrance.destroy = continent_loader.entrance.detach

Class.make_proper_class(continent_loader.entrance, '@CHL>MapLoader>Continent>Loader>Entrance')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- class responsible for exclusively unloading a continent when invoking a zone listener
export type continent_loader_exit = {
	observer: observer;
	zones: {zone};
	
	set_observer: (self: continent_loader_exit, observer: observer) -> (),
	set_zones: (self: continent_loader_exit, zones: {zone}) -> (),
	destroy_observation: (self: continent_loader_entrance) -> (),
} & continent_loader_base

continent_loader.exit = {}
continent_loader.exit.from = {}

function continent_loader.exit.new(arg: continent_loader_arg): continent_loader_exit
	local self: continent_loader_exit = continent_loader.base.new(arg.instances, arg.space)
	
	setmetatable(disguise(self), continent_loader.exit)
	
	self.destroy_observation = empty
	self:set_observer(arg.observer)
	self:set_zones(arg.zones)
	
	return self
end

function continent_loader.exit.set_observer(self: continent_loader_exit, observer: observer)
	if self.observer and self.zones then
		for _, zone in self.zones do
			self.observer:detach(zone)
		end
		
		self:destroy_observation()
	end
	
	self.observer = observer
	
	if observer then
		self.destroy_observation = observer:onPlayerEnter(function(p, zone)
			if not table.find(self.zones, zone) then
				return
			end
			self:unload()
		end)
	end
end

function continent_loader.exit.from.part(arg: continent_loader_arg & {part: BasePart})
	local zone = Zone.Zone.fromPart(arg.part)
	
	arg.zones = {zone}
	
	return continent_loader.exit.new(arg)
end

continent_loader.exit.set_zones = continent_loader.entrance.set_zones
continent_loader.exit.load = continent_loader.entrance.load
continent_loader.exit.unload = continent_loader.entrance.unload
continent_loader.exit.detach = continent_loader.entrance.detach
continent_loader.exit.destroy = continent_loader.entrance.destroy

Class.make_proper_class(continent_loader.exit, '@CHL>MapLoader>Continent>Loader>Exit')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

-- class responsible for loading when an observer is triggered in a zone and unloading a continent when invoking a zone observer seeing items leave the zone
export type continent_loader_area = {
	observer: observer;
	zones: {zone};
	
	destroy_player_enter: (self:continent_loader_area) -> (),
	destroy_player_exit: (self:continent_loader_area) -> (),
	set_observer: (self: continent_loader_exit, observer: observer) -> (),
	set_zones: (self: continent_loader_exit, zones: {zone}) -> (),
} & continent_loader_base

continent_loader.area = {}
continent_loader.area.from = {}

function continent_loader.area.new(arg: continent_loader_arg): continent_loader_area
	local self: continent_loader_area = Object.simple.new(continent_loader.area)
	
	self.destroy_player_enter = empty
	self.destroy_player_exit = empty
	self:set_observer(arg.observer)
	self:set_zones(arg.zones)
	
	return self
end

function continent_loader.area.set_observer(self: continent_loader_area, observer: observer)
	if self.observer and self.zones then
		for _, zone in self.zones do
			self.observer:detach(zone)
		end
		
		self:destroy_player_enter()
		self:destroy_player_exit()
	end
	
	self.observer = observer
	
	if observer then
		self.destroy_player_enter = observer:onPlayerEnter(function(p, zone)
			if not table.find(self.zones, zone) then
				return
			end
			self:load()
		end)
		
		self.destroy_player_exit = observer:onPlayerExit(function(p, zone)
			if not table.find(self.zones, zone) then
				return
			end
			self:unload()
		end)
	end
end

function continent_loader.area.detach(self: continent_loader_exit)
	continent_loader.base.detach(self)
	
	if self.observer then
		self:destroy_player_enter()
		self:destroy_player_exit()
		self.observer = nil
	end
	
	if self.zones then
		self:set_zones{}
	end
end

function continent_loader.area.from.part(arg: continent_loader_arg & {part: BasePart})
	local zone = Zone.Zone.fromPart(arg.part)
	
	arg.zones = {zone}
	
	return continent_loader.area.new(arg)
end

continent_loader.area.set_zones = continent_loader.exit.set_zones
continent_loader.area.load = continent_loader.exit.load
continent_loader.area.unload = continent_loader.exit.unload
continent_loader.area.destroy = continent_loader.exit.destroy

Class.make_proper_class(continent_loader.area, '@CHL>MapLoader>Continent>Loader>Area')

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

--[[
	While universe_loader is a singleton and continent_loader is a class package, universe_loader_2 is another singleton that automatically invokes multiple continent_loaders
]]

universe_loader_2 = {}
universe_loader_2.continent_loaders = {}

function universe_loader_2.load(arg: string | Instance)
	local container = module.get_void()
	local universe = typeof(arg) == 'Instance' and arg or container:FindFirstChild(arg)
	
	assert(universe and universe.Parent == container, 'Universe non-existant or is not under container')
	
	universe_loader.load(universe)
	
	local loading_triggers = universe:FindFirstChild('loading_triggers')
	local observer = universe_loader_2.observer
	local space = universe_loader_2.space or universe_loader.space
	assert(observer, 'Missing universe_loader_2.observer')
	
	if loading_triggers then
		local current_triggers = {}
		for _, trigger: BasePart in loading_triggers:GetChildren() do
			local continent_loader_object = continent_loader.from_part_format_1(trigger, observer, space)
			
			continent_loader_object.space = continent_loader_object.instances[1].Parent
			
			universe_loader_2[trigger] = continent_loader_object
			table.insert(current_triggers, continent_loader_object)
		end
		
		for _, trigger in current_triggers do
			trigger:unload()
		end
	end
end

function universe_loader_2.unload(arg: string)
	local container = module.get_void()
	local space = universe_loader.space
	local universe = typeof(arg) == 'Instance' and arg or universe_loader.space:FindFirstChild(arg)
	
	assert(universe and universe.Parent == space, 'Universe non-existant or is not under space')
	
	if not universe:GetAttribute('__is_map') then
		warn('Attempted to unload a non-universe')
		return
	end
	
	local loading_triggers = universe:FindFirstChild('loading_triggers')
	
	if loading_triggers then
		for _, trigger: BasePart in loading_triggers:GetChildren() do
			local continent_loader_object = universe_loader_2[trigger]
			if continent_loader_object then
				continent_loader_object:load()
				continent_loader_object:destroy()
			end
		end
	end
	
	universe_loader.unload(universe)
end

universe_loader_2.is_loaded = universe_loader.is_loaded
universe_loader_2.add_universe = universe_loader.add_universe

module.universe_loader_2 = universe_loader_2

--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################
--###############################################################################################################################################################################################################

return module
