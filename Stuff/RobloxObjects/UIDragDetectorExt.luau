local module = {}

local Object = require('./Object')
local Class = require('./Class')
local Destructable = require('./@CHL>Destructable')

--#####################################################################################################################################################################
--#####################################################################################################################################################################
--#####################################################################################################################################################################

export type object = {
	dragger: UIDragDetector;
	
	drag_started: RBXScriptConnection;
	drag_ended: RBXScriptConnection;
	
	is_dragging: boolean;
} & Destructable.object

module.object = {}

function module.object.new(dragger: UIDragDetector)
	local self: object = Object.simple.new(module.object)
	
	self.dragger = dragger
	
	self.drag_started = dragger.DragStart:Connect(function()self.is_dragging = true end)
	self.drag_ended = dragger.DragEnd:Connect(function()self.is_dragging = false end)
	
	return self
end

function module.object.destroy(self: object)
	if self.isDestroyed then return end
	
	if self.dragger then
		self.dragger:Destroy()
	end
	
	self.drag_started:Disconnect()
	self.drag_ended:Disconnect()
	self.isDestroyed = true
end

Class.make_proper_class(module.object, '@CHL>UIDragDetectorExt>Object')

--#####################################################################################################################################################################
--#####################################################################################################################################################################
--#####################################################################################################################################################################

export type referral_drag = {
	dragger: object;
	moving: GuiObject;
	detector: GuiObject;
	
	detector_hovered: RBXScriptConnection;
	detector_hover_exit: RBXScriptConnection;
	dragger_hover_ended: RBXScriptConnection;
}

module.referral_drag = {}

function module.referral_drag.new(dragger: object, detector: GuiObject)
	local ui_dragger = dragger.dragger
	local moving = assert(ui_dragger.Parent)
	assert(detector:IsDescendantOf(moving))
	
	local self: referral_drag = Object.simple.new(module.referral_drag)
	
	self.dragger = dragger
	self.moving = moving
	self.detector = detector
	
	self.detector_hovered = detector.MouseEnter:Connect(function(x: number, y: number)
		self.dragger.dragger.Enabled = true
	end)
	
	self.detector_hover_exit = detector.MouseLeave:Connect(function(x: number, y: number)
		if self.dragger.is_dragging then return end
		self.dragger.dragger.Enabled = false
	end)
	
	self.dragger_hover_ended = ui_dragger.DragEnd:Connect(function()
		self.dragger.dragger.Enabled = false
	end)
	
	return self
end

Class.make_proper_class(module.referral_drag, '@CHL>UIDragDetectorExt>ReferralDrag')

--#####################################################################################################################################################################
--#####################################################################################################################################################################
--#####################################################################################################################################################################

--[[
	Should be designated as a temporary class until there is a more direct way to implement of such
]]

local Spring = require('./@CHL>Spring')
local UiInset = require('./@CHL>UIInsets')
local ExtraSprings = require('./@CHL>ExtraSprings')

type v2_spring = Spring.object<Vector2>

export type springed_drag_1 = {
	dragger: object;
	spring: v2_spring;
	referral: GuiObject; -- one being moved
	offset: v2_spring;
	
	update: (self: springed_drag_1, dt: number) -> ();
}

module.springed_drag_1 = {}
module.springed_drag_1.from = {}

function module.springed_drag_1.new(dragger: object, referral: GuiObject, spring: v2_spring): springed_drag_1
	local self: springed_drag_1 = Object.simple.new(module.springed_drag_1)
	local ui_dragger = dragger.dragger
	
	self.dragger = dragger
	self.spring = spring
	self.referral = referral
	self.offset = UiInset.get_inset(dragger.dragger:FindFirstAncestorWhichIsA('ScreenGui').ScreenInsets)
	
	spring.p = self.referral.AbsolutePosition - self.offset
	spring.t = dragger.dragger.Parent.AbsolutePosition
	
	ui_dragger.DragStart:Connect(function(inputPosition: Vector2)
		spring.p = self.referral.AbsolutePosition
	end)
	
	return self
end

function module.springed_drag_1.from.no_spring(dragger: object, referral: GuiObject): springed_drag_1
	local spring = Spring.new(Vector2.zero)
	return module.springed_drag_1.new(dragger, referral, spring)
end

function module.springed_drag_1.from.lone_dragger(dragger: object): springed_drag_1
	local parent: GuiObject = dragger.dragger.Parent
	local equivilent = Instance.new('Frame')
	equivilent.Size = parent.Size
	equivilent.Position = parent.Position
	equivilent.Parent = parent.Parent
	
	return module.springed_drag_1.from.no_spring(dragger, equivilent)
end

function module.springed_drag_1.from.lone_dragger_2(ui_dragger_detector: UIDragDetector): springed_drag_1
	local parent: GuiObject = ui_dragger_detector.Parent
	
	local equivilent = Instance.new('Frame')
	equivilent.Size = parent.Size
	equivilent.Position = parent.Position
	equivilent.Parent = parent.Parent
	equivilent.BackgroundTransparency = 1
	
	ui_dragger_detector.Parent = equivilent
	
	return module.springed_drag_1.from.no_spring(module.object.new(ui_dragger_detector), parent)
end

function module.springed_drag_1.update(self: springed_drag_1, dt: number)
	local dragger = self.dragger
	local spring = self.spring
	local parent = dragger.dragger.Parent

	if dragger.is_dragging then
		spring.t = parent.AbsolutePosition
	end
	
	spring:update(dt)
	
	local result_v2 = spring.p - self.offset
	local result_u2 = UDim2.fromOffset(result_v2.X, result_v2.Y)
	
	self.referral.Position = result_u2
	
	if not dragger.is_dragging then
		parent.Position = result_u2
	end
end

Class.make_proper_class(module.springed_drag_1, '@CHL>UIDragDetectorExt>SpringDrag1')

--#####################################################################################################################################################################
--#####################################################################################################################################################################
--#####################################################################################################################################################################

return module
