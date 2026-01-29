export type accessory_struct = {
	AccessoryType: Enum.AccessoryType;
	IsLayered: boolean;
	AssetId: number;
	Position: Vector3;
	Rotation: Vector3;
	Scale: Vector3;
	Puffiness: number;
	Order: number;
}

export type description_struct = {
	version: number?;
	accessories: {accessory_struct};
	
	climbing_animation: number;
	falling_animation: number;
	idling_animation: number;
	jumping_animation: number;
	mood_animation: number;
	running_animation: number;
	swimming_animation: number;
	walking_animation: number;
	
	face: number;
	head: number;
	left_arm: number;
	left_leg: number;
	right_arm: number;
	right_leg: number;
	torso: number;
	
	graphic_t_shirt: number;
	pants: number;
	shirt: number;
	
	body_type_scale: number;
	depth_scale: number;
	head_scale: number;
	height_scale: number;
	proportion_scale: number;
	width_scale: number;
	
	torso_color: Color3;
	head_color: Color3;
	left_leg_color: Color3;
	right_leg_color: Color3;
	left_arm_color: Color3;
	right_arm_color: Color3;
}

local module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

local BufferWrapper = require('./@CHL>BufferWrapper')
local BinaryStream = require('./@CHL>BinaryStream')
local Bit32Ext = require('./@CHL>Bit32Ext')
local Iterator = require('./@CHL>Iterator')
local Dash = require('./@CHL>DashSingular')

type buffer_w = BufferWrapper.object
type writer = BinaryStream.writer
type reader = BinaryStream.reader

lshift = bit32.lshift
bor = bit32.bor
band = bit32.band
tinsert = table.insert
rshift = bit32.rshift
compose = Dash.compose
struct = {}
struct.from = {}

struct.animation_masks = {
	climbing = 0b_1000_0000,
	falling  = 0b_0100_0000,
	idling   = 0b_0010_0000,
	jumping  = 0b_0001_0000,
	mood     = 0b_0000_1000,
	running  = 0b_0000_0100,
	swimming = 0b_0000_0010,
	walking  = 0b_0000_0001,
}

struct.animation_order = {'climbing', 'falling', 'idling', 'jumping', 'mood', 'running', 'swimming', 'walking'}
struct.body_color_order = {'torso', 'head', 'left_leg', 'left_arm', 'right_leg', 'right_arm'}
struct.body_color_masks = {
	head      = 0b_0001_0000,
	left_leg  = 0b_0000_1000,
	left_arm  = 0b_0000_0100,
	right_leg = 0b_0000_0010,
	right_arm = 0b_0000_0001,
}

--#####################################################################################
--#####################################################################################
--#####################################################################################

function module.get_accessory_type_from_asset_type(enum: Enum.AssetType): Enum.AccessoryType
	if enum == Enum.AssetType.Hat then
		return Enum.AccessoryType.Hat
	end

	local prefix = enum.Name:match('(%a+)Accessory$')

	if prefix then
		return Enum.AccessoryType:FromName(prefix)
	end

	return Enum.AccessoryType.Unknown
end

function module.is_accessory(enum: Enum.AssetType): boolean
	return module.get_accessory_type_from_asset_type(enum) ~= Enum.AccessoryType.Unknown
end

function module.is_layered(enum: Enum.AssetType): boolean
	local value = enum.Value
	
	return value >= 64 and value <= 72
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

local MarketplaceService = require('./@CHL>MarketplaceService')

--[[
function module.get_singleton(): HumanoidDescription
	if script:FindFirstChildWhichIsA('HumanoidDescription') then
		return script:FindFirstChildWhichIsA('HumanoidDescription')
	end
	
	local humanoiddescription = Instance.new('HumanoidDescription')
	
	humanoiddescription.Parent = script
	
	return humanoiddescription
end

function module.prompt_accessory_struct(product_info: MarketplaceService.product_info_result): accessory_struct
	local singleton = module.get_singleton()
	local asset_type = Enum.AssetType:FromValue(product_info.AssetTypeId)
	local is_layered = module.is_layered(asset_type)
	
	local struct = {
		AssetId = product_info.AssetId;
		AccessoryType = module.get_accessory_type_from_asset_type(asset_type);
		IsLayered = is_layered;
	} :: accessory_struct
	
	if is_layered then
		struct.Order = 1
	end
	
	singleton:SetAccessories({struct}, true)
	
	print(singleton:GetAccessories(true))
end

--]]

--#####################################################################################
--#####################################################################################
--#####################################################################################

accessory_struct = {}

function accessory_struct.from_asset(asset: number): accessory_struct
	local product_info = MarketplaceService.get_product_info_async(asset)
	
	return accessory_struct.from_product_info(product_info)
end

function accessory_struct.from_product_info(product_info: MarketplaceService.product_info_result): accessory_struct
	local asset_type = Enum.AssetType:FromValue(product_info.AssetTypeId)
	local is_layered = module.is_layered(asset_type)
	local accessory_type = module.get_accessory_type_from_asset_type(asset_type)
	
	local result: accessory_struct = {}
	result.AssetId = product_info.AssetId
	result.AccessoryType = accessory_type
	result.Position = Vector3.zero
	result.Rotation = Vector3.zero
	result.Scale = Vector3.one
	result.IsLayered = is_layered
	
	if is_layered then
		result.Order = 1
		result.Puffiness = 1
	end
	return result
end

module.accessory_struct = accessory_struct

--#####################################################################################
--#####################################################################################
--#####################################################################################

function read_vector3(self: reader): Vector3
	local result = Vector3.new(
		self:readf32(),
		self:readf32(),
		self:readf32()
	)
	
	return result
end

function read_color3(self: reader): Vector3
	local result = Color3.fromRGB(
		self:readu8(),
		self:readu8(),
		self:readu8()
	)

	return result
end

function struct.from.humanoid_description(humanoid_description: HumanoidDescription): description_struct
	local result: description_struct = {}
	
	result.accessories = humanoid_description:GetAccessories(true)
	
	result.climbing_animation = humanoid_description.ClimbAnimation
	result.falling_animation = humanoid_description.FallAnimation
	result.idling_animation = humanoid_description.IdleAnimation
	result.jumping_animation = humanoid_description.JumpAnimation
	result.mood_animation = humanoid_description.MoodAnimation
	result.running_animation = humanoid_description.RunAnimation
	result.swimming_animation = humanoid_description.SwimAnimation
	result.walking_animation = humanoid_description.WalkAnimation
	
	result.face = humanoid_description.Face
	result.head = humanoid_description.Head
	result.left_arm = humanoid_description.LeftArm
	result.left_leg = humanoid_description.LeftLeg
	result.right_arm = humanoid_description.RightArm
	result.right_leg = humanoid_description.RightLeg
	result.torso = humanoid_description.Torso
	
	result.graphic_t_shirt = humanoid_description.GraphicTShirt
	result.pants = humanoid_description.Pants
	result.shirt = humanoid_description.Shirt
	
	result.body_type_scale = humanoid_description.BodyTypeScale
	result.depth_scale = humanoid_description.DepthScale
	result.head_scale = humanoid_description.HeadScale
	result.height_scale = humanoid_description.HeightScale
	result.proportion_scale = humanoid_description.ProportionScale
	result.width_scale = humanoid_description.WidthScale
	
	result.torso_color = humanoid_description.TorsoColor
	result.head_color = humanoid_description.HeadColor
	result.left_leg_color = humanoid_description.LeftLegColor
	result.right_leg_color = humanoid_description.RightLegColor
	result.left_arm_color = humanoid_description.LeftArmColor
	result.right_arm_color = humanoid_description.RightArmColor
	
	return result
end

function struct.from.reader(reader: reader): description_struct
	local result: description_struct = {}
	
	local d_version = reader:readu8()
	assert(d_version == 0)
	
	-- accessories
	local accessories_amount = reader:readu32()
	
	result.accessories = {}
	
	for i = 1, accessories_amount do
		local accessory_struct: accessory_struct =  {}
		local byte = reader:readu8()
		
		local is_layered = band(byte, 0b_0000_0001) ~= 0
		local accessory_type_num = rshift(byte, 1)
		
		accessory_struct.IsLayered = is_layered
		accessory_struct.AccessoryType = Enum.AccessoryType:FromValue(accessory_type_num)
		accessory_struct.AssetId = reader:readu64()
		accessory_struct.Position = read_vector3(reader)
		accessory_struct.Rotation = read_vector3(reader)
		accessory_struct.Scale = read_vector3(reader)
		
		if is_layered then
			accessory_struct.Puffiness = reader:readf64()
			accessory_struct.Order = reader:readu32()
		end
		
		tinsert(result.accessories, accessory_struct)
	end
	
	-- animations
	local presence_flag = reader:readu8()
	
	for _, v in module.struct.animation_order do
		local mask = module.struct.animation_masks[v]
		local is_present = band(presence_flag, mask) ~= 0
		local index = `{v}_animation`
		
		if is_present then
			result[index] = reader:readu64()
		else
			result[index] = 0
		end
	end
	
	-- values before body color
	result.face = reader:readu64()
	result.head = reader:readu64()
	result.left_arm = reader:readu64()
	result.left_leg = reader:readu64()
	result.right_arm = reader:readu64()
	result.right_leg = reader:readu64()
	result.torso = reader:readu64()
	
	result.graphic_t_shirt = reader:readu64()
	result.pants = reader:readu64()
	result.shirt = reader:readu64()
	
	local scale = reader:readu16() / 0xFFFF
	result.body_type_scale = scale
	result.depth_scale = reader:readf64()
	result.head_scale = reader:readf64()
	result.height_scale = reader:readf64()
	result.proportion_scale = reader:readf64()
	result.width_scale = reader:readf64()
	
	-- body colors
	local colors = {}
	
	local flags = reader:read_bits(5)
	local torso_color = read_color3(reader)
	
	tinsert(colors, torso_color)
	
	for i = 2, #struct.body_color_order do
		local label = struct.body_color_order[i]
		local mask = struct.body_color_masks[label]
		local color
		
		if band(flags, mask) == 0 then
			color = read_color3(reader)
		else
			local value = reader:read_bits(2)
			local index = #colors - value
			
			color = colors[index]
		end
		
		tinsert(colors, color)
		result[`{label}_color`] = color
	end
	
	result.torso_color = torso_color
	
	return result
end

function struct.from.buffer_w(buffer_w: buffer_w): description_struct
	local iterator = BufferWrapper.iterator.new(buffer_w.referral)
	
	return struct.from.iterator(iterator)
end

struct.from.iterator = compose(BinaryStream.reader.new, struct.from.reader) :: (byte_iterator: Iterator.simple<number>) -> description_struct

struct.to = {}

function struct.to.humanoid_description(description: description_struct): HumanoidDescription
	local humanoid_description = Instance.new('HumanoidDescription')
	
	humanoid_description:SetAccessories(description.accessories, true)
	
	humanoid_description.ClimbAnimation = description.climbing_animation
	humanoid_description.FallAnimation = description.falling_animation
	humanoid_description.IdleAnimation = description.idling_animation
	humanoid_description.JumpAnimation = description.jumping_animation
	humanoid_description.MoodAnimation = description.mood_animation
	humanoid_description.RunAnimation = description.running_animation
	humanoid_description.SwimAnimation = description.swimming_animation
	humanoid_description.WalkAnimation = description.walking_animation
	
	humanoid_description.Face = description.face
	humanoid_description.Head = description.head
	humanoid_description.LeftArm = description.left_arm
	humanoid_description.LeftLeg = description.left_leg
	humanoid_description.RightArm = description.right_arm
	humanoid_description.RightLeg = description.right_leg
	humanoid_description.Torso = description.torso
	
	humanoid_description.GraphicTShirt = description.graphic_t_shirt
	humanoid_description.Pants = description.pants
	humanoid_description.Shirt = description.shirt
	
	humanoid_description.BodyTypeScale = description.body_type_scale
	humanoid_description.DepthScale = description.depth_scale
	humanoid_description.HeadScale = description.head_scale
	humanoid_description.HeightScale = description.height_scale
	humanoid_description.ProportionScale = description.proportion_scale
	humanoid_description.WidthScale = description.width_scale
	
	humanoid_description.TorsoColor = description.torso_color
	humanoid_description.HeadColor = description.head_color
	humanoid_description.LeftLegColor = description.left_leg_color
	humanoid_description.RightLegColor = description.right_leg_color
	humanoid_description.LeftArmColor = description.left_arm_color
	humanoid_description.RightArmColor = description.right_arm_color
	
	return humanoid_description
end

function write_vector3(self: BinaryStream.writer, v3: Vector3)
	self:writef32(v3.X)
	self:writef32(v3.Y)
	self:writef32(v3.Z)
end

function write_color3(self: BinaryStream.writer, c3: Color3)
	self:writeu8((c3.R * 255) // 1)
	self:writeu8((c3.G * 255) // 1)
	self:writeu8((c3.B * 255) // 1)
end

function struct.to.binary_data(description: description_struct, writer: BinaryStream.writer)
	-- version
	writer:writeu8(0x00)
	
	-- accessories
	writer:writeu32(#description.accessories)
	
	for _, accessory_struct in description.accessories do
		-- accessory type + is layered
		local byte = lshift(accessory_struct.AccessoryType.Value, 1)
		
		if accessory_struct.IsLayered then
			byte = bor(byte, 0b_0000_0001)
		end
		
		writer:writeu8(byte)
		
		-- other values in accessory_struct
		writer:writeu64(accessory_struct.AssetId)
		write_vector3(writer, accessory_struct.Position)
		write_vector3(writer, accessory_struct.Rotation)
		write_vector3(writer, accessory_struct.Scale)
		
		if accessory_struct.IsLayered then
			writer:writef64(accessory_struct.Puffiness)
			writer:writeu32(accessory_struct.Order)
		end
	end
	
	-- animations
	local byte = 0x00
	
	for _, animation in struct.animation_order do
		local animation_id = description[`{animation}_animation`]
		
		if not (animation_id and animation_id ~= 0) then continue; end
		
		byte = bor(byte, struct.animation_masks[animation])
	end
	
	writer:writeu8(byte)

	for _, animation in struct.animation_order do
		local mask = struct.animation_masks[animation]
		local is_present = band(byte, mask) ~= 0
		
		if not is_present then continue; end
		
		local animation_id = description[`{animation}_animation`]
		
		writer:writeu64(animation_id)
	end
	
	-- multiple other values before body color
	writer:writeu64(description.face)
	writer:writeu64(description.head)
	writer:writeu64(description.left_arm)
	writer:writeu64(description.left_leg)
	writer:writeu64(description.right_arm)
	
	writer:writeu64(description.right_leg)
	writer:writeu64(description.torso)
	
	writer:writeu64(description.graphic_t_shirt)
	writer:writeu64(description.pants)
	writer:writeu64(description.shirt)
	
	local scale = (description.body_type_scale * 0xFFFF) // 1
	writer:writeu16(scale)
	writer:writef64(description.depth_scale)
	writer:writef64(description.head_scale)
	writer:writef64(description.height_scale)
	writer:writef64(description.proportion_scale)
	writer:writef64(description.width_scale)
	
	-- body colors
	-- compression idea: either write color3 (3bytes) or referrals (2 bits)
	local expected_values = {}
	local flags = 0
	
	for i, v in struct.body_color_order do
		local j = i - 1
		local color = description[`{v}_color`]
		
		while struct.body_color_order[j] do
			local j_label = struct.body_color_order[j]
			local j_color = description[`{j_label}_color`]
			
			if j_color == color then
				break
			end
			
			j -= 1
		end
		
		local referral_value = i - j - 1
		local is_using_color = j == 0 or referral_value > 0b11
		
		if is_using_color then
			tinsert(expected_values, color)
		else
			tinsert(expected_values, referral_value)
		end
		
		if i ~= 1 and not is_using_color then
			flags = bor(flags, struct.body_color_masks[v])
		end
	end
	
	writer:write_bits(flags, 5)
	
	for _, v in expected_values do
		if typeof(v) == 'Color3' then
			write_color3(writer, v)
		else
			writer:write_bits(v, 2)
		end
	end
end

function struct.to.buffer_w(description: description_struct): buffer_w
	local consumer = BufferWrapper.consumer.new()
	local writer = BinaryStream.writer.new(consumer)
	
	struct.to.binary_data(description, writer)
	
	while writer.offset ~= 0 do
		writer:write_bits(0, 1)
	end
	
	return consumer:build()
end

module.struct = struct

--#####################################################################################
--#####################################################################################
--#####################################################################################

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
