--[[
	Bulk records for export
]]

--############################################################################################################################################################################################################
--############################################################################################################################################################################################################
--############################################################################################################################################################################################################

-- singlular rig animation

local Class = require('./Class')
local Object = require('./Object')
local Promise = require('./@CHL>Promise')

local module = {}

RunService = game:GetService('RunService')

Promise.implant()

type promise<T...> = Promise.modified_object<T...>

export type singular_rig_animation_player = {
	animator: Animator,
	current_track: promise<AnimationTrack>;
	current_frame: number;
	
	touch_track: (self: singular_rig_animation_player, arg: Animation | KeyframeSequence | Content | string) -> promise<AnimationTrack>;
	set_frame: (self: singular_rig_animation_player, frame: number)->();
}

singular_rig_animation_player = {}

function singular_rig_animation_player.new(animator: Animator): singular_rig_animation_player
	local self: singular_rig_animation_player = Object.simple.new(singular_rig_animation_player)
	
	self.animator = animator
	
	return self
end

function await_track_load(track: AnimationTrack, explicit_length_check: number?): AnimationTrack
	if not explicit_length_check then
		return track
	end
	
	while track.Length ~= explicit_length_check do
		task.wait(1)
	end
	
	return track
end

function singular_rig_animation_player.touch_track(self: singular_rig_animation_player, arg: Animation | KeyframeSequence | Content | string): promise<AnimationTrack>
	local animation, explicit_length
	
	if typeof(arg) == 'Instance' and arg:IsA('KeyframeSequence') then
		explicit_length = arg.Length
		arg = game:GetService('KeyframeSequenceProvider'):RegisterKeyframeSequence(arg)
	end
	
	if typeof(arg) == 'string' then
		arg = Content.fromUri(arg)
	end
	
	if typeof(arg) == 'Content' then
		animation = Instance.new('Animation')
		animation.AnimationContent = arg
		animation.Parent = script
	elseif typeof(arg) == 'Instance' and arg:IsA('Animation') then
		animation = arg
	end
	
	local animator = self.animator
	local track = animator:GetTrackByAnimationId(animation.AnimationId) or animator:LoadAnimation(animation)
	
	self.current_track = Promise.try(await_track_load, track, explicit_length)
		:upon(function(track)
			if not track.IsPlaying then
				track:Play(0)
			end
			
			track:AdjustSpeed(0)
			
			return track
		end)
	
	return self.current_track
end

function singular_rig_animation_player.set_frame(self: singular_rig_animation_player, frame: number)
	local track = assert(self.current_track, 'current track is not set')
	
	track.TimePosition = frame
	
	return Promise.from_event(RunService.PreSimulation)
end

Class.make_proper_class(singular_rig_animation_player, '@CHL>BulkRecord>SingularRigAnimation')

module.singular_rig_animation_player = singular_rig_animation_player

--############################################################################################################################################################################################################
--############################################################################################################################################################################################################
--############################################################################################################################################################################################################

local Iterator = require('./@CHL>Iterator')

export type animation_bulk_keyframe_iterator = {
	referral: singular_rig_animation_player;
	step: number;
	current_time: number;
} & Iterator.simple<promise<AnimationTrack>>

animation_bulk_keyframe_iterator = {}

function animation_bulk_keyframe_iterator.new(referral: singular_rig_animation_player): animation_bulk_keyframe_iterator
	local self: animation_bulk_keyframe_iterator = Object.simple.new(animation_bulk_keyframe_iterator)
	
	self.referral = referral
	self.step = 1/60
	self.current_time = 0
	
	return self
end

function animation_bulk_keyframe_iterator.can_proceed(self: animation_bulk_keyframe_iterator)
	return self.current_time <= self.referral.current_track:expect().Length
end

function animation_bulk_keyframe_iterator.proceed(self: animation_bulk_keyframe_iterator)
	if not self:can_proceed() then return;end
	
	local referral = self.referral
	local promise = referral:set_frame(self.current_time)
	local length = referral.current_track:expect().Length
	
	if self.current_time == length then
		self.current_time += 1
	else
		self.current_time = math.min(length, self.current_time + self.step)
	end
	
	return promise
end

Class.make_proper_class(animation_bulk_keyframe_iterator, '@CHL>BulkRecord>AnimationBulkKeyFrameIterator')

module.animation_bulk_keyframe_iterator = animation_bulk_keyframe_iterator

--############################################################################################################################################################################################################
--############################################################################################################################################################################################################
--############################################################################################################################################################################################################

local Map = require('./@CHL>Map')

type dict<T> = Map.dictionary<T>

export type super_transform_struct = {
	part_0_path: string;
	part_1_path: string;
	name: string?;
}

export type animated_rig_state_iterator = {
	rig: Instance;
	super_transformations: {super_transform_struct};
	time_iterator: animation_bulk_keyframe_iterator;
} & Iterator.simple<dict<CFrame>>

local hierarchy = require('./@CHL>Hierarchy')

animated_rig_state_iterator = {}

function animated_rig_state_iterator.new(rig: Instance, time_iterator: animation_bulk_keyframe_iterator): animated_rig_state_iterator
	local self: animated_rig_state_iterator = Object.simple.new(animated_rig_state_iterator)
	
	self.rig = rig
	self.time_iterator = time_iterator
	
	return self
end

function animated_rig_state_iterator.can_proceed(self: animated_rig_state_iterator)
	return self.time_iterator:can_proceed()
end

function animated_rig_state_iterator.proceed(self: animated_rig_state_iterator)
	if not self:can_proceed() then return end
	
	local super_transformations = self.super_transformations
	local time_iterator = self.time_iterator
	local rig = self.rig
	
	local track = time_iterator:proceed():expect()
	
	local result = {}
	
	for i, super_transformation in super_transformations do
		local part_0 = hierarchy.invoke_query{
			query = super_transformation.part_0_path;
			root_instance = rig;
			current_working_instance = rig
		}
		
		assert(part_0 and part_0:IsA('BasePart'), 'part_0 not found')
		
		local part_1 = hierarchy.invoke_query{
			query = super_transformation.part_1_path;
			root_instance = rig;
			current_working_instance = rig
		}
		
		assert(part_1 and part_1:IsA('BasePart'), 'part_0 not found')
		
		local name = super_transformation.name or super_transformation.part_1_path
		
		local transformation = part_0.CFrame:Inverse() * part_1.CFrame
		
		result[name] = transformation
	end
	
	return result
end

animated_rig_state_iterator.default = {}
animated_rig_state_iterator.default.super_transformations = {}
animated_rig_state_iterator.default.super_transformations.r6 = {
	{part_0_path = 'HumanoidRootPart'; part_1_path = 'Torso';},
	{part_0_path = 'Torso';            part_1_path = 'Left Arm';},
	{part_0_path = 'Torso';            part_1_path = 'Right Arm';},
	{part_0_path = 'Torso';            part_1_path = 'Left Leg';},
	{part_0_path = 'Torso';            part_1_path = 'Right Leg';},
	{part_0_path = 'Torso';            part_1_path = 'Head';},
}

animated_rig_state_iterator.super_transformations = animated_rig_state_iterator.default.super_transformations.r6

Class.make_proper_class(animated_rig_state_iterator, '@CHL>BulkRecord>AnimatedRigStateIterator')

module.animated_rig_state_iterator = animated_rig_state_iterator

--############################################################################################################################################################################################################
--############################################################################################################################################################################################################
--############################################################################################################################################################################################################

return module
