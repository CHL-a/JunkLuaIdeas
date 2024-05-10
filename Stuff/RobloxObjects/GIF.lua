local Objects = script.Parent
local Object = require(Objects.Object)

local module = {}

--#######################################################################################
--#######################################################################################
--#######################################################################################

--[[
	Note: A 0 based class
]]

export type base = {
	rows: number;
	columns: number;
	frame_index: number;
	frames: number;
	
	proceed_frame: (self: base) -> ();
	get_coordinates: (self: base) -> (number, number);
} & Object.object_inheritance

--#######################################################################################
--#######################################################################################
--#######################################################################################

Base = {}

function Base.new(rows: number, columns: number): base
	local self: base = Object.from.class(Base)
	
	self.rows = rows
	self.columns = columns
	self.frame_index = 0
	self.frames = rows * columns
	
	return self
end

function Base.proceed_frame(self: base)
	self.frame_index = (self.frame_index + 1) % self.frames 
end

function Base.get_coordinates(self: base)
	return self.frame_index % self.columns,
		self.frame_index // self.rows
end

Base.__index = Base
Base.className = 'GIF/Base'
module.Base = Base

--#######################################################################################
--#######################################################################################
--#######################################################################################

local Class = require(Objects.Class)

export type image_label_wrapper = {
	referral: ImageLabel;
	image_size: Vector2;
	tile_size: Vector2;
	
	update_referral: (self: image_label_wrapper) -> ();
	get_coordinates: (self: image_label_wrapper) -> (number, number);
} & Class.subclass<base>

export type image_label_wrapper_args = {
	referral: ImageLabel;
	image_size: Vector2;
	rows: number;
	columns: number;
}

ImageLabelWrapper = {}

function ImageLabelWrapper.new(args: image_label_wrapper_args): image_label_wrapper
	local rows = args.rows
	local columns = args.columns
	local image_size = args.image_size
	local self: image_label_wrapper = Base.new(rows, columns):__inherit(ImageLabelWrapper)
	
	self.image_size = image_size
	self.tile_size = image_size / Vector2.new(rows, columns)
	self.referral = args.referral
	self.referral.ImageRectSize = self.tile_size
	
	return self
end

function ImageLabelWrapper.update_referral(self: image_label_wrapper)
	self.referral.ImageRectOffset = self.tile_size * Vector2.new(self:get_coordinates())
end

ImageLabelWrapper.__index = ImageLabelWrapper
ImageLabelWrapper.className = 'GIF/ImageLabelWrapper'
module.ImageLabelWrapper = ImageLabelWrapper

return module
