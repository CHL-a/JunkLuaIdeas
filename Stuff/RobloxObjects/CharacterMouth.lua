--[[
  {
		name = '@CHL/CharacterMouth';
		targetRepository = 'Shared';
		packageType = 'url';
		dependencies = {
			"Object",
			'Class',
			'EventPackage',
			'RuntimeUpdater',
		};
		url = 'fill in here, I hope';
  }
--]]
-- TYPES
local Objects = script.Parent

local Object = require(Objects.Object)
local Class = require(Objects.Class)
local EventPackage = require(Objects.EventPackage)
local RuntimeUpdater = require(Objects.RuntimeUpdater)

local module = setmetatable({}, Object)

export type object<A> = {
	speech: string;
	character: A;
	pieceSpeed: number;
	delayedTime: number;
	i: number;
	speak: (self: object<A>, m: string) -> ();
	setCharacter: (self: object<A>, info: A) -> ();
	
	characterChanged: EventPackage.event<A>;
	__characterChanged: EventPackage.package<A>;
	pieceShown: EventPackage.event<string>;
	__pieceShown: EventPackage.package<string>;
	spoke: EventPackage.event<>;
	__spoke: EventPackage.package<>;
} & Class.subclass<Object.object>
  & RuntimeUpdater.updatable

-- MAIN

function module.new<A>(init: A?): object<A>
	local self: object<A> = Class.inherit(Object.new(), module)
	
	if init then
		self:setCharacter(init)
	end
	
	self.i = 1
	self.speech = ''
	self.pieceSpeed = .1
	self.delayedTime = 0
	self.canUpdate = false
	
	self:__constructEvent(
		'characterChanged', 
		'pieceShown',
		'spoke'
	)
	
	return self
end

module.setCharacter = function<A>(self: object<A>, info: A)
	self.character = info
	self.__characterChanged:fire(info)
end

module.speak = function<A>(self: object<A>, s: string)
	self.speech = s
	self.i = 1
	self.delayedTime = 0
	self.canUpdate = true
	self.__spoke:fire()
end

module.update = function<A>(self: object<A>, dt: number)
	self.delayedTime -= dt
	
	if self.delayedTime <= 0 then
		local i = self.i
		
		if i > #self.speech then
			self.canUpdate = false
			return;
		end
		
		self.__pieceShown:fire(self.speech:sub(i,i))
		self.delayedTime = self.pieceSpeed
		self.i += 1
	end
end

module.__index = module
module.className = '@CHL/CharacterMouth'

return module
