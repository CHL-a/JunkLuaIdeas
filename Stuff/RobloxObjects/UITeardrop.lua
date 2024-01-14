--// TYPES
type __constructorArgs = {
	states: {
		initSize: UDim2?;
		finalSize: UDim2?;
		initTransparency: number?;
		finalTransparency: number?;
		initColor: Color3?;
		finalColor: Color3?;
	}?;
	tweenInfo: TweenInfo?;
}
export type constructorArgs = __constructorArgs

type __object = {
	parent: GuiObject;
	frame: Frame;
	tweenInfo: TweenInfo;
	initSize: UDim2;
	finalSize: UDim2;
	initTransparency: number;
	finalTransparency: number;
	initColor: Color3;
	finalColor: Color3;
	play: (self: __object, position: UDim2) -> nil;
	reset: (self: __object) -> nil;
}
export type object = __object

--// MAIN
local module = {}

local Objects = script.Parent
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise

module.__index = module

local teardrop = Instance.new('Frame')
teardrop.AnchorPoint = Vector2.new(.5,.5)
teardrop.Size = UDim2.fromOffset(50,50)
teardrop.Transparency = 1
teardrop.Parent = script
teardrop.BackgroundColor3 = Color3.new(1,1,1)
module.teardrop = teardrop

local uiCorner = Instance.new('UICorner')
uiCorner.CornerRadius = UDim.new(1)
uiCorner.Parent = teardrop

local defaultTweenInfo = TweenInfo.new()
module.defaultTweenInfo = defaultTweenInfo

function module.new(parent: GuiObject, args: __constructorArgs?): __object
	local self: __object = disguise(setmetatable({}, module))
	local frame = teardrop:Clone()
	
	self.parent = parent
	
	frame.Parent = parent
	self.frame = frame
	
	self.tweenInfo = args and args.tweenInfo or module.defaultTweenInfo
	
	self.initSize = UDim2.fromOffset(50,50)
	self.finalSize = UDim2.fromOffset(100,100)
	
	self.initTransparency = .5
	self.finalTransparency = 1
	
	self.initColor = Color3.new(1,1,1)
	self.finalColor = self.initColor
	
	if args and args.states then
		for i, v in next, args.states do
			if v == nil then continue;end
			
			disguise(self)[i] = v;
		end
	end
	
	return self
end

module.reset = function(self: __object)
	local frame = self.frame
	
	frame.Size = self.initSize
	frame.BackgroundTransparency = self.initTransparency
	frame.BackgroundColor3 = self.initColor
end

--[[
	This method should be documented because determining variable `relative` based on mouse 
	position on a ScreenGui.
	
	To do so, we need to declare some variables:
	a = mouse position
	  * Mind that variable a can be obtained in any way but `a` in our case is based on the 
	    absolute position of the mouse, where the origin is at the top left corner
	  * Obtained using `game:GetService('UserInputService'):GetMouseLocation()`, a Vector2
	b = absolute position of the parent GuiObject
	  * The absolute position of the gui object is defined by `GuiObject.AbsolutePosition`, a 
	    Vector2 and has their origin set below the Roblox Gui Inset, regardless whether 
	    `ScreenGui.IgnoreGuiInset` is true or false.
	c = origin compensation
	  * Due to the above two values possessing different origins, this variable is responsible
	    for compensating both values. Thankfully, c is a constant Vector2 and even more
	    fortunate, that it is easily obtainable as defined:
	    `game:GetService('GuiService'):GetGuiInset()`
	
	Thus, relative can be defined as = a - b - c
--]]
module.play = function(self: __object, relative: UDim2)
	local frame = self.frame
	local result = 	game:GetService('TweenService'):Create(frame,self.tweenInfo,{
		Size = self.finalSize;
		BackgroundColor3 = self.finalColor;
		BackgroundTransparency = self.finalTransparency
	})
	
	frame.Position = relative
	
	result:Play()
	
	return result
end

return module
