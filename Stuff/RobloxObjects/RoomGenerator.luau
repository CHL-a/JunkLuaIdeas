local Objects = game:GetService('ReplicatedStorage').Objects
local Object = require(Objects.Object)
local Class = require(Objects.Class)

export type door = {
	load_next: boolean;
	part: Part;
}

module = {}
Door = {}
disguise = require(Objects.LuaUTypes).disguise

function Door.new(part: Part): door
	local door: door = disguise{}

	door.part = part
	door.load_next = true

	part.Transparency = .9
	part.CanCollide = false

	return door
end

--#################################################################################################################################################
--#################################################################################################################################################
--#################################################################################################################################################

local InstanceUtils = require(Objects["@CHL>InstanceUtils"])

export type room = {
	entrance: door?;
	doors: {door}?;
	container: Model;
	internal_collision: {Region3};

	move: (self: room, to: CFrame)->();
	connect_door: (self: room, door: door)->();
	clone: (self: room)->room;
	can_exist: (self: room, to:door)->boolean;
} & Object.object_inheritance

tinsert = table.insert
Room = {}

function Room.new(model: Model): room
	local doors = assert(model:FindFirstChild('Doors'), 'Bad room: rooms are expected to have doors')
	local collision = assert(model:FindFirstChild('Collision'), 'Bad room: rooms are expected to have collisions')

	local self: room = Object.from.class(Room)
	
	model:AddTag(Room.tag)
	self.container = model
	
	local entrance = doors:FindFirstChild('Entrance')
	if entrance and entrance:IsA('Part') then
		entrance.Anchored = true
		self.entrance = Door.new(entrance)
	end

	for _, v in doors:GetChildren() do
		if not v:IsA('Part') then
			warn('attempting to use a non part as door')
			continue
		end

		if v == entrance then
			continue
		end

		if not self.doors then
			self.doors = {}
		end

		v.Anchored = true

		table.insert(disguise(self.doors), Door.new(v))
	end
	
	for _, v: Part in collision:GetChildren() do
		assert(v:IsA'Part')
		
		v.CanCollide = false
		
	end
	
	return self
end

function Room.clone(self: room)
	local clone = Room.new(self.container:Clone())

	return clone
end

function Room.move(self: room, to: CFrame)
	self.container:PivotTo(to)
end

function Room.connect_door(self: room, to: door)
	local entrance = assert(self.entrance, 'no entrace for connecting doors')
	
	local displacement = self.container:GetPivot():Inverse() * entrance.part.CFrame
	
	self:move(to.part.CFrame * displacement:Inverse())
end

function Room.can_exist(self: room, to: door)
	local piv = self.container.WorldPivot
	local result = true
	
	self:connect_door(to)
	
	for _, v: Part in disguise(self).container.Collision:GetChildren() do
		if not v:IsA('Part') then
			warn'not part'
		end
		
		local list = workspace:GetPartBoundsInBox(v.CFrame, v.Size)
		
		for _, v in list do
			local ancestor = InstanceUtils.get_tagged_ancestor(v, Room.tag)
			
			if not ancestor then continue end
			
			if ancestor == self.container then continue end
			
			result = false
			break
		end
	end
	
	wait(1)
	
	self:move(piv)
	
	return result
end


Room.tag = 'is_room'
module.room = Room
Class.makeProperClass(Room, 'RoomGenerator>Room')

--#################################################################################################################################################
--#################################################################################################################################################
--#################################################################################################################################################

local Dash = require(Objects["@CHL>DashSingular"])

export type generator = {
	queue: {door};
	rooms: {room};
	parent: Instance;
	random: Random;
	map: {room};

	place_starter_room: (self: generator, room, to: CFrame?)->();
	place_room: (self:generator, door, room)->();
	pick_room: (self: generator, ref: door)->room?;
	evaluate_queue: (self: generator)->();
} & Object.object_inheritance

Generator = {}

function Generator.new(parent: Instance?): generator
	local self: generator = Object.from.class(Generator)
	
	self.queue = {}
	self.parent = parent or workspace
	self.random = Random.new()
	self.rooms = {}
	self.map = {}
	
	return self
end

function Generator.place_starter_room(self: generator, room: room, to: CFrame?)
	room:move(to or CFrame.identity)
	
	if not room.doors then return; end
	
	for _, v in room.doors do
		tinsert(self.queue, v)
	end
	
end

-- temp because currently results in infinite rooms
A = 1
LIMIT = 50

function Generator.evaluate_queue(self: generator)
	while (#self.queue > 0) do
		if #self.map > LIMIT then
			break
		end
		
		if A > LIMIT then
			break
		end
		
		local door = table.remove(self.queue, 1)

		if not door.load_next then continue end
		
		local room = self:pick_room(door)
		
		if not room then
			local last_room = table.remove(self.map)
			local doors = assert(Dash.last(self.map).doors)
			
			last_room.container:Destroy()
			
			table.insert(self.queue, assert(doors[1]))
			A += 1
			continue
		end
		
		self:place_room(door, room)
	end
end

function Generator.pick_room(self: generator, ref: door)
	local list = table.clone(self.rooms)
	local room: room = nil

	self.random:Shuffle(list)
	
	while #list > 0 do
		local item: room = disguise(table.remove(list, 1))
		
		
		if not item:can_exist(ref) then
			continue;
		end
		
		-- temp
		if true then
			room = item
			break
		end
	end
	
	return room
end

function Generator.place_room(self: generator, door: door, room: room)
	local clone = room:clone()
	clone:connect_door(door)
	clone.container.Parent = self.parent
	
	table.insert(self.map, clone)
	
	if not clone.doors then
		return
	end
	for _, v in clone.doors do
		if not v.load_next then continue end

		tinsert(self.queue, v)
	end
end

module.generator = Generator
Class.makeProperClass(Generator, 'RoomGenerator>Generator')

return module
