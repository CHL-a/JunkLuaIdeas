--[[
	a library for client-sided effects
	
	currently type only and has resources
]]

local module = {}

local GlobalAttachmentHolder = require('./@CHL>GlobalAttachmentHolder')
local RuntimeUpdater = require('./@CHL>RuntimeUpdater')
local Destructable = require('./@CHL>Destructable')

-- all types below denote as a type that has various implementations, thus they're all abstractions
export type effect_base = {
	get_cframe: (self: effect_base)->CFrame;
	set_cframe: (self: effect_base, CFrame)->();
} & Destructable.object

export type projectile = effect_base & RuntimeUpdater.updatable

export type emitter = {
	attachment: Attachment;
	
	set_attachment: (self: emitter, Attachment)->();
	emit: (self: emitter, amount: number?)->();
} & effect_base

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

local Object = require('./Object')
local Class = require('./Class')

export type particle_emitter = {
	particle_emitter: ParticleEmitter
} & emitter

particle_emitter = {}

function particle_emitter.new(particle_emitter_inst: ParticleEmitter, attachment): particle_emitter
	local self: particle_emitter = Object.simple.new(particle_emitter)

	self.particle_emitter = particle_emitter_inst
	self:set_attachment(attachment)

	return self
end

function particle_emitter.emit(self: particle_emitter, amount: number) self.particle_emitter:Emit(amount or 1) end
function particle_emitter.get_cframe(self: particle_emitter): CFrame? return self.attachment.WorldCFrame end
function particle_emitter.set_cframe(self: particle_emitter, cframe: CFrame) self.attachment.WorldCFrame = cframe end

function particle_emitter.set_attachment(self: particle_emitter, attachment: Attachment) 
	self.attachment = attachment 
	self.particle_emitter.Parent = attachment
end

function particle_emitter.destroy(self: particle_emitter) self.particle_emitter:Destroy() self.particle_emitter = nil end

Class.make_proper_class(particle_emitter, 'ClientEffects>ParticleEmitter')

module.particle_emitter = particle_emitter

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

-- denotes that one single audio is playing
export type sound_emitter = {
	attachment: Attachment;
	sound: Sound;

	set_attachment: (self: sound_emitter, Attachment)->();
	play: (self: sound_emitter)->();
} & effect_base

sound_emitter = {}
sound_emitter.from = {}

function sound_emitter.new(audio_inst: Sound, attachment: Attachment): sound_emitter
	local self: sound_emitter = Object.simple.new(sound_emitter)

	self.sound = audio_inst
	self:set_attachment(attachment)

	return self
end

function sound_emitter.play(self: sound_emitter) self.sound:Play() end
function sound_emitter.get_cframe(self: sound_emitter): CFrame? return self.attachment.WorldCFrame end
function sound_emitter.set_cframe(self: sound_emitter, cframe: CFrame) self.attachment.WorldCFrame = cframe end

function sound_emitter.set_attachment(self: sound_emitter, attachment: Attachment) 
	self.attachment = attachment 
	self.sound.Parent = attachment
end

function sound_emitter.destroy(self: sound_emitter) self.sound:Destroy() self.sound = nil end

function sound_emitter.from.id(id: number, attachment: Attachment): sound_emitter
	local sound = Instance.new('Sound')
	sound.SoundId = 'rbxassetid://'..id
	return sound_emitter.new(sound, attachment)
end

Class.make_proper_class(sound_emitter, 'ClientEffects>SoundEmitter')

module.sound_emitter = sound_emitter

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

-- purpose: to play an audio but based on availibility, it will not attempt to play a playing audio
export type sound_list_emitter = {
	attachment: Attachment;

	set_attachment: (self: sound_list_emitter, Attachment)->();

	play: (self: sound_list_emitter)->();
} & effect_base

export type sound_list_emitter_array = {
	i: number;
	sounds: {Sound};

	get_index: (self: sound_list_emitter_array, offset: number?)->number;
	get_sound_i: (self: sound_list_emitter_array, offset: number?)->Sound;
	get_availible_sound: (self: sound_list_emitter_array)->Sound;
} & sound_list_emitter

tinsert = table.insert
sound_list_emitter_array = {}
sound_list_emitter_array.from = {}

function sound_list_emitter_array.new(audio_insts: {Sound}, attachment: Attachment): sound_list_emitter_array
	local self: sound_list_emitter_array = Object.simple.new(sound_list_emitter_array)

	self.i = 1
	self.sounds = audio_insts
	self:set_attachment(attachment)

	return self
end

function sound_list_emitter_array.from.sound(sound: Sound, attachment: Attachment): sound_list_emitter_array 
	return sound_list_emitter_array.new({sound}, attachment)
end

function sound_list_emitter_array.from.id(id: number, attachment: Attachment): sound_list_emitter_array
	local sound = Instance.new('Sound')
	sound.SoundId = 'rbxassetid://'..id

	return sound_list_emitter_array.from.sound(sound, attachment)
end

function sound_list_emitter_array.get_index(self: sound_list_emitter_array, offset: number?)return (self.i - 1 + (offset or 0)) % #self.sounds + 1 end
function sound_list_emitter_array.play(self: sound_list_emitter_array)local sound = self:get_availible_sound()sound:Play()end

function sound_list_emitter_array.get_sound_i(self: sound_list_emitter_array, offset: number?): Sound
	local sounds = self.sounds
	local index = self:get_index(offset)
	return sounds[index]
end

function sound_list_emitter_array.destroy(self: sound_list_emitter_array)
	for _, sound in self.sounds do
		sound:Destroy()
	end

	self.sounds = nil
end


function sound_list_emitter_array.set_attachment(self: sound_list_emitter_array, attachment: Attachment)
	self.attachment = attachment

	for _, sound in self.sounds do
		sound.Parent = attachment
	end
end

function sound_list_emitter_array.get_availible_sound(self: sound_list_emitter_array): Sound
	local size = #self.sounds

	for i = 1, size do
		i -= 1

		local sound = self:get_sound_i(i)
		if not sound.IsPlaying then 
			self.i = i + 1
			return sound
		end
	end

	local clone = self.sounds[1]:Clone()
	clone.Parent = self.attachment

	self.i = size + 1

	tinsert(self.sounds, clone)

	return clone
end

Class.make_proper_class(sound_list_emitter_array, 'ClientEffects>SoundListEmitter>Array')

module.sound_list_emitter_array = sound_list_emitter_array

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

GlobalAttachmentHolder.get_holder()

module.holder = GlobalAttachmentHolder

return module
