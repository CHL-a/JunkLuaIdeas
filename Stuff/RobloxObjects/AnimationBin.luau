--[[
	Returns an animation based on input
]]

local Object = require('./Object')
local Map = require('./@CHL>Map')
local Class = require('./Class')
local Ladder = require('./@CHL>LadderFunction')

type map<I,V> = Map.simple<I,V>
type ladder<A..., R...> = Ladder.object<A..., R...>

export type bin_ladder = ladder<(any), (Content)>

export type object = {
	ladder: bin_ladder;
	
	-- can also return Content.none
	get: (self: object, input: any)->Content;
}

local module = {}

KeyframeSequenceProvider = game:GetService('KeyframeSequenceProvider')
tinsert = table.insert

function module.new(ladder: bin_ladder): object
	local self: object = Object.simple.new(module)
	self.ladder = ladder
	return self
end

function module.get(self: object, arg: any)
	return self.ladder:call(arg)
end

module.__index = module

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

export type argument = {
	keyframe_folder: Folder?; -- may have rung too
	animation_folder: Folder?;
}

rung_result = Ladder.rung_result.new

module.supplied = {}

function module.supplied.new(argument: argument): object
	local rungs: {Ladder.rung<any> | Ladder.rung_function<any>} = {}
	
	if argument.keyframe_folder and argument.animation_folder then
		tinsert(rungs, function(arg)
			if typeof(arg)=='string' then
				local found = argument.animation_folder:FindFirstChild(arg)
				
				if found and found:IsA('Animation') then
					return rung_result('end', Content.fromUri(found.AnimationId))
				end
				
				found = argument.keyframe_folder:FindFirstChild(arg)
				
				if found and found:IsA('KeyframeSequence') then
					local hash = KeyframeSequenceProvider:RegisterKeyframeSequence(found)
					local animation = Instance.new('Animation')
					animation.AnimationId = hash
					
					return rung_result('end', Content.fromUri(hash))
				end
			end
			
			return rung_result('continue', arg)
		end)
	end
	
	
	local ladder = Ladder.ladder.new(rungs)
	return module.new(ladder)
end

return module
