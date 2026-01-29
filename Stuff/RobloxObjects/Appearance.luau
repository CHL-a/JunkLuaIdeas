--[[
	An extension of humanoiddescription which is a datatype of CHL implemented datatype
]]

local HumanoidDescriptionLib = require('./@CHL>HumanoidDescription')

export type description_struct = HumanoidDescriptionLib.description_struct
export type appearance_rig_type = 'keep' | 'r15' | 'r6' | 'custom'
export type content_type = 'asset' | 'content'
export type game_accessory_id_type = 'uint' | 'uint_length_string'

export type face_struct = {
	name: string;
	content_type: content_type;
	content: Content;
	transparency: number;
	z_index: number;
	color: Color3;
}

export type appearance_struct = {
	version: number?;

	is_byte_aligned: boolean;
	rig_type: appearance_rig_type;
	tail_size: number;
	should_override_face: boolean;
	game_accessory_id_type: game_accessory_id_type;

	humanoid_description: description_struct;

	face_array: {face_struct};

	game_accessories: {number} | {string};
	
	pants_color: Color3;
	shirt_color: Color3;
}

local Dash = require('./@CHL>DashSingular')
local module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

module.flags = {}

module.flags.is_byte_aligned        = 0b_1000_0000_0000_0000
module.flags.rig_type_keep          = 0b_0000_0000_0000_0000
module.flags.rig_type_r6            = 0b_0010_0000_0000_0000
module.flags.rig_type_r15           = 0b_0100_0000_0000_0000
module.flags.rig_type_custom        = 0b_0110_0000_0000_0000
module.flags.tail_size_mask         = 0b_0001_1100_0000_0000
module.flags.should_override_face   = 0b_0000_0010_0000_0000
module.flags.game_accessory_id_type = 0b_0000_0001_0000_0000
module.flags.has_pants_color        = 0b_0000_0000_1000_0000
module.flags.has_shirt_color        = 0b_0000_0000_0100_0000

module.flags.content_type_asset     = 0b_0000_0000
module.flags.content_type_content   = 0b_0100_0000
module.flags.content_type_mask      = 0b_1100_0000
module.flags.color_present          = 0b_0010_0000
module.flags.transparency_present   = 0b_0001_0000
module.flags.z_index_present        = 0b_0000_1000
module.flags.name_present           = 0b_0000_0100

--#####################################################################################
--#####################################################################################
--#####################################################################################

local BinaryStream = require('./@CHL>BinaryStream')
local BufferWrapper = require('./@CHL>BufferWrapper')
local Bit32Ext = require('./@CHL>Bit32Ext')

--#####################################################################################
--#####################################################################################
--#####################################################################################+

face_struct = {}

function face_struct.decal_to_struct(decal: Decal): face_struct
	local uri = decal.TextureContent.Uri
	local is_asset = get_asset_from_uri(uri)
	
	local face_struct: face_struct = {
		content = decal.TextureContent;
		name = decal.Name;
		content_type = is_asset and 'asset' or 'content';
		transparency = decal.Transparency;
		z_index = decal.ZIndex;
		color = decal.Color3;
	}
	
	return face_struct
end

function face_struct.struct_to_face(struct: face_struct): Decal
	local decal = Instance.new('Decal')

	decal.TextureContent = struct.content

	if struct.name         then decal.Name = struct.name                 end
	if struct.color        then decal.Color3 = struct.color              end
	if struct.transparency then decal.Transparency = struct.transparency end
	if struct.z_index      then decal.ZIndex = struct.z_index            end

	return decal
end

module.face_struct = face_struct

--#####################################################################################
--#####################################################################################
--#####################################################################################

type reader = BinaryStream.reader

tinsert = table.insert
rshift = bit32.rshift
compose = Dash.compose
flag_test = Bit32Ext.flag_test
to_bit_enum = Bit32Ext.to_bit_enum
module.struct = {}

function read_color3(self: reader): Vector3
	local result = Color3.fromRGB(
		self:readu8(),
		self:readu8(),
		self:readu8()
	)

	return result
end

function read_length_string(self: reader): string
	local length = self:readu32()
	return self:read_string(length)
end

function get_asset_from_uri(uri: string)
	local result = uri:match('^rbxassetid://(%d+)$') or 
		uri:match('^http://www%.roblox%.com/asset/%?id=(%d+)')
	
	return result
end

function module.struct.value_to_appearance_rig_type(value: number): appearance_rig_type?
	for i, v in module.struct.appearance_rig_types do
		if v == value then
			return i
		end
	end
end

function module.struct.value_to_game_accessory_id_type(value: number): game_accessory_id_type?
	for i, v in module.struct.game_accessory_id_types do
		if v == value then
			return i
		end
	end
end

module.struct.from = {}

function module.struct.from.blank(): appearance_struct
	return {
		version = 0;

		is_byte_aligned = true;
		rig_type = 'keep';
		tail_size = 0;
		should_override_face = false;
		game_accessory_id_type = 'uint';

		humanoid_description = nil;

		face_array = {};

		game_accessories = {};
	}
end

function module.struct.from.description_struct(description: description_struct): appearance_struct
	local result = module.struct.from.blank()
	
	result.humanoid_description = description

	return result
end

function module.struct.from.basic_character(character: Model, should_override_face: boolean?): appearance_struct
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	assert(humanoid, 'No humanoid found in character')
	
	local result: appearance_struct = module.struct.from.humanoid_description(humanoid:GetAppliedDescription())
	local head = character:FindFirstChild('Head')
	local pants = character:FindFirstChildWhichIsA('Pants')
	local shirt = character:FindFirstChildWhichIsA('Shirt')
	
	result.should_override_face = should_override_face ~= false
	
	if head then
		for _, v in head:GetChildren() do
			if not (v:IsA('Decal') and v.Face == Enum.NormalId.Front) then continue end
			
			local face_struct_result = face_struct.decal_to_face_struct(v)
			tinsert(result.face_array, face_struct_result)
		end
	end
	
	if pants then
		result.pants_color = pants.Color3
	end
	
	if shirt then
		result.shirt_color = shirt.Color3
	end
	
	return result
end

function module.struct.from.data_blob(reader: reader): appearance_struct
	local result: appearance_struct = module.struct.from.blank()
	
	-- version
	result.version = reader:readu8()
	
	-- flags
	local flags = reader:readu16()
	
	local has_pants_color = flag_test(flags, module.flags.has_pants_color)
	local has_shirt_color = flag_test(flags, module.flags.has_shirt_color)
	
	result.is_byte_aligned = flag_test(flags, module.flags.is_byte_aligned)
	result.rig_type = module.struct.value_to_appearance_rig_type(
		to_bit_enum(flags, module.flags.rig_type_custom)
	)
	result.tail_size = to_bit_enum(flags, module.flags.tail_size_mask)
	result.should_override_face = flag_test(flags, module.flags.should_override_face)
	
	local game_accessory_id_type = module.struct.value_to_game_accessory_id_type(
		to_bit_enum(flags, module.flags.game_accessory_id_type)
	)
	result.game_accessory_id_type = game_accessory_id_type
	
	local has_pants_color = flag_test(flags, module.flags.has_pants_color)
	local has_shirt_color = flag_test(flags, module.flags.has_shirt_color)
	
	-- humanoid description
	reader:readu32() -- size
	
	result.humanoid_description = HumanoidDescriptionLib.struct.from.reader(reader)
	
	while reader.offset ~= 0 do
		reader:read_bits(1)
	end
	
	-- faces
	local faces_amount = reader:readu8()
	
	for i = 1, faces_amount do
		local face_struct: face_struct = {}
		
		-- flags
		local flags = reader:readu8()
		local content_type: content_type = to_bit_enum(flags, module.flags.content_type_mask)
			== module.flags.content_type_asset and 'asset' or 'content'
		local has_color = flag_test(flags, module.flags.color_present)
		local has_transparency = flag_test(flags, module.flags.transparency_present)
		local has_z_index = flag_test(flags, module.flags.z_index_present)
		local has_name = flag_test(flags, module.flags.name_present)
		
		face_struct.content_type = content_type
		
		-- content
		local content_uri;
		
		if content_type == 'asset' then
			local asset = reader:readu64()
			content_uri = `rbxassetid://{asset}`
		else
			content_uri = `rbxasset://{read_length_string(reader)}`
		end
		
		face_struct.content = Content.fromUri(content_uri)
		
		-- color
		if has_color then
			face_struct.color = read_color3(reader)
		end
		
		-- transparency
		if has_transparency then
			face_struct.transparency = reader:readu16() / 0xFFFF
		end
		
		-- z index
		if has_z_index then
			face_struct.z_index = reader:readi8()
		end
		
		-- name
		if has_name then
			face_struct.name = read_length_string(reader)
		end
		
		tinsert(result.face_array, face_struct)
	end
	
	-- accessories
	local accessories_amount = reader:readu16()
	
	for i = 1, accessories_amount do
		if game_accessory_id_type == 'uint' then
			tinsert(result.game_accessories, reader:readu32())
		else
			tinsert(result.game_accessories, read_length_string(reader))
		end
	end
	
	if has_pants_color then
		result.pants_color = read_color3(reader)
	end
	
	if has_shirt_color then
		result.shirt_color = read_color3(reader)
	end
	
	return result
end

function module.struct.from.buffer_w(buffer_w: buffer_w): appearance_struct
	local byte_iterator = BufferWrapper.iterator.new(buffer_w.referral)
	local reader = BinaryStream.reader.new(byte_iterator)
	
	return module.struct.from.data_blob(reader)
end

module.struct.from.humanoid_description = compose(HumanoidDescriptionLib.struct.from.humanoid_description, module.struct.from.description_struct)
	:: (HumanoidDescription)->appearance_struct

--#####################################################################################
--#####################################################################################
--#####################################################################################

type writer = BinaryStream.writer
type buffer_w = BufferWrapper.object

band = bit32.band
bor = bit32.bor
module.struct.to = {}

function write_length_string(self:writer, s: string)
	self:writeu32(#s)
	self:write_string(s)
end

function write_color3(self: BinaryStream.writer, c3: Color3)
	self:writeu8((c3.R * 255) // 1)
	self:writeu8((c3.G * 255) // 1)
	self:writeu8((c3.B * 255) // 1)
end

function module.struct.to.data_blob(appearance: appearance_struct, writer: writer)
	-- version
	writer:writeu8(0)
	
	-- flags
	local has_pants_color = appearance.pants_color and appearance.pants_color ~= Color3.fromRGB(255, 255, 255)
	local has_shirt_color = appearance.shirt_color and appearance.shirt_color ~= Color3.fromRGB(255, 255, 255)
	
	local flags = bor(
		module.flags.is_byte_aligned,
		module.flags.rig_type_keep,
		-- tail size is 0x00
		module.flags.should_override_face,
		module.flags.game_accessory_id_type
	)
	
	if has_pants_color then
		flags = bor(flags, module.flags.has_pants_color)
	end
	
	if has_shirt_color then
		flags = bor(flags, module.flags.has_shirt_color)
	end
	
	writer:writeu16(flags)

	-- humanoid description
	local data_blob = HumanoidDescriptionLib.struct.to.buffer_w(appearance.humanoid_description)
	
	writer:writeu32(data_blob:len())
	
	local buffer_iterator = BufferWrapper.iterator.new(data_blob.referral)
	
	while buffer_iterator:can_proceed() do
		writer:writeu8(buffer_iterator:proceed())
	end
	
	-- face array size
	writer:writeu8(#appearance.face_array)
	
	for _, v in appearance.face_array do
		-- flags
		local is_asset = v.content_type == 'asset' or get_asset_from_uri(v.content.Uri)
		local flags = is_asset 
			and module.flags.content_type_asset
			or  module.flags.content_type_content
		
		local is_using_color = v.color and v.color ~= Color3.fromRGB(255, 255, 255)
		local is_using_transparency = v.transparency and v.transparency ~= 0
		local is_using_z_index = v.z_index and v.z_index ~= 1
		local is_using_name = v.name and v.name ~= 'Decal'
		
		if is_using_color        then flags = bor(flags, module.flags.color_present)        end
		if is_using_transparency then flags = bor(flags, module.flags.transparency_present) end
		if is_using_z_index      then flags = bor(flags, module.flags.z_index_present)      end
		if is_using_name         then flags = bor(flags, module.flags.name_present)         end
		
		writer:writeu8(flags)
		
		-- decal struct properties
		-- content
		local uri = v.content.Uri
		
		if is_asset then
			local asset = tonumber(get_asset_from_uri(uri))
			assert(asset)
			
			writer:writeu64(asset)
		else
			local suffix = uri:match('^rbxasset://(.+)')

			assert(suffix)
			
			write_length_string(writer, suffix)
		end
		
		-- color
		if is_using_color then
			write_color3(writer, v.color)
		end
		
		-- transparency
		if is_using_transparency then
			writer:writeu16((math.clamp(v.transparency,0,1) * 0xFFFF) // 1)
		end
		
		-- z_index
		if is_using_z_index then
			writer:writei8(v.z_index)
		end
		
		-- name
		if is_using_name then
			write_length_string(writer, v.name)
		end
	end
	
	-- accessory array
	writer:writeu16(#appearance.game_accessories)
	
	for _, v in appearance.game_accessories do
		assert(typeof(v) == 'string') -- implement number case
		
		write_length_string(writer, v)
	end
	
	-- pants and shirt colors
	if has_pants_color then
		write_color3(writer, appearance.pants_color)
	end
	
	if has_shirt_color then
		write_color3(writer, appearance.shirt_color)
	end
end

function module.struct.to.buffer_w(appearance: appearance_struct): buffer_w
	local consumer = BufferWrapper.consumer.new()
	local writer = BinaryStream.writer.new(consumer)
	
	module.struct.to.data_blob(appearance, writer)
	
	return consumer:build()
end

function module.struct.to.basic_character(appearance: appearance_struct, character: Model)
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	assert(humanoid, 'No humanoid found in character')
	
	humanoid:ApplyDescriptionAsync(
		HumanoidDescriptionLib.struct.to.humanoid_description(appearance.humanoid_description)
	)

	local head = character:FindFirstChild('Head')
	local pants = character:FindFirstChildWhichIsA('Pants')
	local shirt = character:FindFirstChildWhichIsA('Shirt')
	
	if head then
		if appearance.should_override_face then
			local face = head:FindFirstChild('face')
			if face then
				face:Destroy()
			end
		end
		
		for _, v in head:GetChildren() do
			if not (v:IsA('Decal') and v.Name ~= 'face' and v.Face == Enum.NormalId.Front) then
				continue
			end
			
			v:Destroy()
		end
		
		for _, v: face_struct in appearance.face_array do
			local decal = face_struct.struct_to_face(v)
			
			decal.Parent = head
		end
	end
	
	if pants and appearance.pants_color then
		pants.Color3 = appearance.pants_color
	end
	
	if shirt and appearance.shirt_color then
		shirt.Color3 = appearance.shirt_color
	end
end

module.struct.appearance_rig_types = {
	keep   = 0;
	r15    = 1;
	r6     = 2;
	custom = 3;
}

module.struct.game_accessory_id_types = {
	uint   = 0;
	string = 1;
}

return module
