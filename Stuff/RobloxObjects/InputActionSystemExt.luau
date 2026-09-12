-- subject to change due to unreviewed event package

local Signal = require('./@averlyst>NamedSignal')
local Map = require('./@CHL>Map')

type dict<T> = Map.dictionary<T>
type empty = ()->()

export type base = {
	input_action: InputAction;
	connections: dict<RBXScriptConnection>;
	pressed_timestamp: number;
	released_timestamp: number;
	
	get_pressed_time: (self: base) -> (number);
	get_released_time: (self: base) -> (number);
	activated: Signal.Signal<empty>;
	detach: (self: base) -> ();
	destroy: (self: base) -> ();
}

--######################################################################################################################################################################
--######################################################################################################################################################################
--######################################################################################################################################################################

local module = {}

module.base = {}

function module.base.detach(self: base)
	self.input_action = nil
	
	for _, v in self.connections do
		v:Disconnect()
	end
	
	table.clear(self.connections)
end

function module.base.destroy(self: base)
	local action = self.input_action
	
	self:detach()
	
	if action then
		action:Destroy()
	end
end

function module.base.get_pressed_time(self: base): number
	return self.released_timestamp - self.pressed_timestamp
end

function module.base.get_released_time(self: base): number
	return self.pressed_timestamp - self.released_timestamp
end

--######################################################################################################################################################################
--######################################################################################################################################################################
--######################################################################################################################################################################

local Class = require('./Class')
local Object = require('./Object')
local Promise = require('./@CHL>Promise')

type promise<T...> = Promise.modified_object<T...>

export type explicit_press = {
	promise: promise<>;
	taps: number?;
} & base

explicit_press = {}

function explicit_press.new(input_action: InputAction): explicit_press
	local self: explicit_press = Object.simple.new(explicit_press)
	
	self.input_action = input_action
	self.connections = {}
	self.activated = Signal.new()
	self.pressed_timestamp = 0
	self.released_timestamp = 0
	self.taps = 0
	
	self.connections.pressed = input_action.Pressed:Connect(function()
		self.pressed_timestamp = workspace.DistributedGameTime
		
		Promise.any({
			Promise.from_event(self.input_action.Released),
			Promise.delay(module.press_length)
		}):upon(function(held_length)
			if held_length then
				self.taps = 0
				return
			end
			
			self.taps += 1
		end):upon_call(task.wait, module.release_length):tap(function()
			if self.taps == 1 then
				self.activated:Fire()
			end
			
			self.taps = 0
		end)
	end)
	
	--[[
	self.connections.released = input_action.Released:Connect(function()
		self.released_timestamp = workspace.DistributedGameTime
	end)
	--]]
	
	return self
end

explicit_press.detach = module.base.detach
explicit_press.destroy = module.base.destroy
explicit_press.get_pressed_time = module.base.get_pressed_time
explicit_press.get_released_time = module.base.get_released_time

Class.make_proper_class(explicit_press, 'InputActions>ExplicitPress')

module.explicit_press = explicit_press

module.press_length = .3
module.release_length = .2

--######################################################################################################################################################################
--######################################################################################################################################################################
--######################################################################################################################################################################

export type explicit_double_press = {
	did_tap: boolean;
} & base

explicit_double_press = {}

function explicit_double_press.new(input_action: InputAction): explicit_double_press
	local self: explicit_double_press = Object.simple.new(explicit_double_press)
	
	self.input_action = input_action
	self.connections = {}
	self.activated = Signal.new()
	self.pressed_timestamp = 0
	self.released_timestamp = 0
	
	self.connections.pressed = input_action.Pressed:Connect(function()
		self.pressed_timestamp = workspace.DistributedGameTime
		
		local negative_press = self:get_released_time()
		
		if negative_press > module.press_length then return end
		
		self.activated:Fire()
	end)
	
	self.connections.released = input_action.Released:Connect(function()
		self.released_timestamp = workspace.DistributedGameTime
		
		local press = self:get_pressed_time()
		
		if press <= module.press_length then 
			self.did_tap = true
		else
			self.did_tap = false
		end
	end)
	
	return self
end

explicit_double_press.detach = module.base.detach
explicit_double_press.destroy = module.base.destroy
explicit_double_press.get_pressed_time = module.base.get_pressed_time
explicit_double_press.get_released_time = module.base.get_released_time

Class.make_proper_class(explicit_double_press, 'InputActions>ExplicitDoublePress')

module.explicit_double_press = explicit_double_press

--######################################################################################################################################################################
--######################################################################################################################################################################
--######################################################################################################################################################################

export type explicit_hold = {
	
} & base

explicit_hold = {}

function explicit_hold.new(input_action: InputAction): explicit_hold
	local self: explicit_hold = Object.simple.new(explicit_hold)
	
	self.input_action = input_action
	self.connections = {}
	self.activated = Signal.new()
	
	self.connections.pressed = input_action.Pressed:Connect(function()
		Promise.any({
			Promise.from_event(self.input_action.Released),
			Promise.delay(module.press_length)
		}):upon(function(held_length)
			if held_length then
				self.activated:Fire()
			end
		end)
	end)
	
	return self
end

explicit_hold.detach = module.base.detach
explicit_hold.destroy = module.base.destroy
explicit_hold.get_pressed_time = module.base.get_pressed_time
explicit_hold.get_released_time = module.base.get_released_time

Class.make_proper_class(explicit_hold, 'InputActions>ExplicitHold')

module.explicit_hold = explicit_hold

--######################################################################################################################################################################
--######################################################################################################################################################################
--######################################################################################################################################################################


return module
