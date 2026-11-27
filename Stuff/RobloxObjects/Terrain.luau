--[[
	Binary format for terrain, using little endian by the default, it's format is as follows:
	
	Specific types
	+-------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	|types  |description                                                                                                                                                                    |
	+-------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	|v3int  |describes a vector 3 in int form due to specific conditions, is deemed to be a int[3]                                                                                          |
	|v3     |vector 3d comprised of 3 floats                                                                                                                                                |
	|stream0|stream of bytes, of which it's own format will be specified                                                                                                                    |
	|x[y]   |array of type x of amount y, if y is not specified, then it is null or default terminated                                                                                      |
	|alpha  |is deemed to be an element of the unit interval, internally the number is divided by the max, given an explicit binary size, ex: an alpha spanning over a ubyte has their value|
	|       |read and then divided by 0xFF, for a ushort, it is divded by 0xFFFF and so on                                                                                                  |
	+-------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	
	file format 0
	+------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
	|start |type   |description                                                                                                                                                |
	+------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
	|0     |uint   |version                                                                                                                                                    |
	|4     |v3int  |position of region3                                                                                                                                        |
	|8     |v3     |size of region3                                                                                                                                            |
	|12    |v3uint |size of 3d map                                                                                                                                             |
	|16    |pair1[]|array of pair1s, specifically, an enum of materials as a uint and the canonical bit length as a ubyte, if the material read is 0, then the array is deemed |
	|      |       |complete and the bit length is not read                                                                                                                    |
	|16+x  |stream0|stream for material, array of length in ubytes and the material code, because length 0 is redundant, if the length is 0, then the 3d array ends            |
	|16+x+y|stream0|stream for occupancies, it is deemed to be an array of indicators and values, to save on bits this stream takes advantage of the fact that 0 and 1 are     |
	|      |       |the most common values within the unit interval, the following bit is read:                                                                                |
	|      |       | * if the bit read is 0, then the next bit is the value, and a uint is read for the amount                                                                 |
	|      |       | * if the bit read is 1, then the next ushort is deemed to be an alpha value                                                                               |
	|      |       |array ends if the mode bit is 0, then if literal is 0 and then if the amount is 0                                                                          |
	+------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------------+
]]

local module = {}

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

local Map = require('./@CHL>Map')
local Iterator = require('./@CHL>Iterator')
local Class = require('./Class')
local Object = require('./Object')

type iterator<A, B...> = Iterator.simple<A, B...>
type map<I, V> = Map.simple<I, V>
export type array_3d<T> = 
	map<number,
		map<number,
			map<number,T>
		>
	>

array_3d = {}
t_insert = table.insert

function array_3d.size_of(value: array_3d<any>): Vector3
	return value.Size or Vector3.new(
		#value,
		#value[1],
		#value[1][1]
	)
end

function array_3d.insert<T>(array_3d_value: array_3d<T>, value: T)
	if not array_3d_value[1] then
		array_3d_value[1] = {{}}
	end
	
	local face = array_3d_value[#array_3d_value]
	local row = face[#face]
	local size = array_3d.size_of(array_3d_value)
	
	if Vector3.new(#array_3d_value, #face, #row) == size then
		print(array_3d_value, value)
		error('capacity reached')
	end
	
	t_insert(row, value)
	
	if #row == size.Z then
		if #face == size.Y then
			if #array_3d_value ~= size.X then
				array_3d_value[#array_3d_value + 1] = {{}}
			end
		else
			t_insert(face, {})
		end
	end
end

function array_3d.is_equal<T>(left: array_3d<T>, right: array_3d<T>): boolean
	local size = array_3d.size_of(left)
	
	if size ~= array_3d.size_of(right) then
		return false
	end
	
	local iterator_left = module.array_3d_iterator.new(left)
	local iterator_right = module.array_3d_iterator.new(right)
	
	while iterator_left:can_proceed() and iterator_right:can_proceed() do
		local material_left = iterator_left:proceed()
		local material_right = iterator_right:proceed()
		
		if material_left ~= material_right then
			return false
		end
	end
	
	return true
end

function array_3d.clone<T>(array_3d_value: array_3d<T>): array_3d<T>
	local result = table.clone(array_3d_value)
	
	for x, x_face in result do
		result[x] = table.clone(x_face)
		
		for y, y_row in x_face do
			result[x][y] = table.clone(y_row)
		end
	end
	
	return result
end

module.array_3d = array_3d

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

export type array_3d_iterator<T> = {
	array_3d: array_3d<T>;
	x: number;
	y: number;
	z: number;
} & iterator<T>

array_3d_iterator = {}

function array_3d_iterator.new<T>(array_3d: array_3d<T>): array_3d_iterator<T>
	local self: array_3d_iterator<T> = Object.simple.new(array_3d_iterator)
	assert(array_3d, 'missing array_3d')
	
	self.array_3d = array_3d
	self.x = 1
	self.y = 1
	self.z = 1
	
	return self
end

function array_3d_iterator.can_proceed<T>(self: array_3d_iterator<T>): T
	return self.array_3d[self.x]
end

function array_3d_iterator.proceed<T>(self: array_3d_iterator<T>): T
	local x = self.x
	if not self.array_3d then
		print(self)
		print(debug.traceback())
	end
	local array_2d = self.array_3d[x]
	local result = array_2d[self.y][self.z]
	
	self.z += 1
	
	if not array_2d[self.y][self.z] then
		self.z = 1
		self.y += 1
		
		if not array_2d[self.y] then
			self.y = 1
			self.x += 1
		end
	end
	
	return result
end

Class.make_proper_class(array_3d_iterator, '@CHL>TerrainFormat>array_3d_iterator')

module.array_3d_iterator = array_3d_iterator

function array_3d.count_map_of<T>(array_3d: array_3d<T>): map<T, number>
	local iterator = array_3d_iterator.new(array_3d)
	local result = {}
	
	while iterator:can_proceed() do
		local element = iterator:proceed()
		
		result[element] = (result[element] or 0) + 1
	end
	
	return result
end

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

export type struct_0 = {
	region_3: Region3,
	materials: array_3d<Enum.Material>;
	occupancies: array_3d<number>;
}

struct_0 = {}

function struct_0.new(region_3: Region3, materials: array_3d<Enum.Material>, occupancy: array_3d<number>): struct_0
	return {
		region_3 = region_3,
		materials = materials,
		occupancies = occupancy
	} :: struct_0
end

function struct_0.from_region_on_terrain(region_3: Region3, terrain: Terrain?): struct_0
	terrain = terrain or workspace.Terrain
	local materials, occupancy = terrain:ReadVoxels(region_3, 4)
	
	return struct_0.new(region_3, materials, occupancy)
end

function struct_0.write_to_terrain(self: struct_0, terrain: Terrain?)
	terrain = terrain or workspace.Terrain
	
	terrain:WriteVoxels(self.region_3, 4, self.materials, self.occupancies)
end

function struct_0.destroy(struct_0)
	struct_0.region_3 = nil
	
	for x, row in struct_0.materials do
		if x == 'Size' then
			continue
		end
		for y, col in row do
			table.clear(col)
		end
		
		table.clear(row)
	end
end

function struct_0.is_equal(left: struct_0, right: struct_0): boolean
	local result;
	local size = array_3d.size_of(left.materials)
	
	result = left.region_3 == right.region_3 and
		array_3d.is_equal(left.materials, right.materials)
	
	if not result then
		return false
	end
	
	return result
end

function struct_0.clone(original: struct_0): struct_0
	local result = table.clone(original)
	
	result.materials = array_3d.clone(original.materials)
	result.occupancies = array_3d.clone(original.occupancies)
	
	return result
end

module.struct_0 = struct_0

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

local BinaryStream = require('./@CHL>BinaryStream')
local Queue = require('./@CHL>LinkedQueue')
local Huffman = require('./@CHL>Huffman')

export type reader = BinaryStream.msbit_reader
export type writer = BinaryStream.msbit_writer
type queue<T> = Queue.object<T>

type byte_iterator = iterator<number>

export type serializer_0 = {
	struct: struct_0;
	queue: queue<number>;
	writer: writer;
	materials_iterator: array_3d_iterator<Enum.Material>;
	occupancy_iterator: array_3d_iterator<number>;
	closed: boolean;
	
	write_huffman_code: (self: serializer_0, code: number, bits: number) -> ();
	reset: (self: serializer_0) -> ();
	header_write: (self: serializer_0) -> ();
} & byte_iterator

serializer_0 = {}
band = bit32.band
rshift = bit32.rshift

function serializer_0.new(struct: struct_0): serializer_0
	local self: serializer_0 = Object.simple.new(serializer_0)
	
	self.struct = struct
	self.queue = Queue.default.new()
	self.writer = BinaryStream.msbit_writer.new(self.queue)
	
	return self
end

function serializer_0.can_proceed(self: serializer_0): boolean
	return not self.queue:is_empty() or
		not self.closed
		--not self.materials_iterator or 
		--self.materials_iterator:can_proceed() or 
		--not self.occupancy_iterator or 
		--self.occupancy_iterator:can_proceed()
end

function serializer_0.header_write(self: serializer_0)
	local writer = self.writer
	local struct = self.struct
	
	writer:writeu32(0) -- version
	
	local region = struct.region_3:ExpandToGrid(4)
	local position = region.CFrame.Position
	
	writer:writei32(position.X) -- position
	writer:writei32(position.Y)
	writer:writei32(position.Z)
	
	local size = region.Size
	
	writer:write_float(size.X) -- size
	writer:write_float(size.Y)
	writer:write_float(size.Z)
	
	size = array_3d.size_of(struct.materials) -- array3d size
	writer:writeu32(size.X)
	writer:writeu32(size.Y)
	writer:writeu32(size.Z)
end

function serializer_0.reset(self: serializer_0)
	self.materials_iterator = nil
	self.occupancy_iterator = nil
	self.current = nil
	self.map = nil
	self.closed = false
end

function serializer_0.proceed(self: serializer_0): number
	local queue = self.queue
	local struct = self.struct
	local writer = self.writer
	
	if not queue:is_empty() then
		return queue:dequeue()
	end
	
	local materials_iterator = self.materials_iterator
	
	if not materials_iterator then
		local count_map = array_3d.count_map_of(struct.materials)
		local nodes: {Huffman.node<number>} = {}
		
		for material, count in count_map do
			local value = material.Value
			
			table.insert(nodes, {
				value = value;
				amount = count;
				has_value = true;
			} :: Huffman.node<number>)
		end
		
		local tree_builder = Huffman.tree_builder.new(nodes)
		local root = tree_builder:all()
		local huffman_table = Huffman.to_huffman_table(root)
		
		Huffman.canonical.compress(huffman_table)
		
		local materials_map = {}
		
		for _, struct in huffman_table do
			local symbol = struct.symbol
			local bit_length = struct.bit_length
			
			writer:writeu32(symbol)
			writer:writeu8(bit_length)
			
			materials_map[symbol] = struct
		end
		
		writer:writeu32(0)
		
		self.materials_iterator = array_3d_iterator.new(struct.materials)
		self.map = materials_map
		self.current = self.materials_iterator:proceed()
		
		return self:proceed()
	end
	
	if materials_iterator:can_proceed() then
		local length = 1
		local material: Enum.Material = self.current
		
		while true do
			if not materials_iterator:can_proceed() then
				self.current = nil
				break
			end
			
			local compare = materials_iterator:proceed()
			
			if compare and compare == material then
				length += 1
			else
				self.current = compare
				break
			end
		end
		
		local struct: Huffman.base_code_struct<number> = self.map[material.Value]
		
		while length > 0 do
			local chunk_length = math.min(0xFF, length)
			
			length -= chunk_length
			
			writer:writeu8(chunk_length)
			self:write_huffman_code(struct.code, struct.bit_length)
		end
		
		return self:proceed()
	end
	
	local occupancy_iterator = self.occupancy_iterator
	
	if not occupancy_iterator then
		if self.current then
			local struct = self.map[self.current.Value]
			writer:writeu8(1)
			writer:write_bits(struct.code, struct.bit_length)
		end
		
		writer:writeu8(0)
		
		local occupancy_iterator = array_3d_iterator.new(self.struct.occupancies)
		
		self.occupancy_iterator = occupancy_iterator
		self.current = occupancy_iterator:proceed()
		
		return self:proceed()
	end
	
	if occupancy_iterator:can_proceed() then
		local current = self.current
		local changed
		
		if current == 0 or current == 1 then
			local check
			local length = 1
			
			while occupancy_iterator:can_proceed() do
				check = occupancy_iterator:proceed()
				
				if check ~= current then
					break
				else
					length += 1
				end
			end
			
			while length > 0 do
				local chunk_length = math.min(0xFFFF, length)
				
				length -= chunk_length
				
				writer:write_bits(0, 1)
				writer:write_bits(current, 1)
				writer:writeu16(chunk_length)
			end
			
			if check ~= current then
				changed = check
			end
		else
			writer:write_bits(1, 1)
			
			local alpha = (current * 0xFFFF) // 1
			
			writer:writeu16(alpha)
			
			if occupancy_iterator:can_proceed() then
				changed = occupancy_iterator:proceed()
			end
		end
		
		self.current = changed
		
		return self:proceed()
	else
		if self.current then
			writer:write_bits(1, 1)
			
			local alpha = (self.current * 0xFFFF) // 1
			
			writer:writeu16(alpha)
		end
		
		writer:write_bits(0, 1)
		writer:write_bits(0, 1)
		writer:writeu16(0)
		
		while writer.offset ~= 0 do
			writer:write_bits(0, 1)
		end
		
		self.closed = true
		
		return self:proceed()
	end
end

function serializer_0.write_huffman_code(self: serializer_0, code: number, bits: number)
	for i = bits, 1, -1 do
		local bit = band(rshift(code, i - 1), 0x01)
		
		self.writer:write_bits(bit, 1)
	end
end

Class.make_proper_class(serializer_0, '@CHL>TerrainFormat>serializer_0')

struct_0.serializer = serializer_0

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

export type deserializer_0 = {
	result: struct_0;
	voxel_spanning_size: Vector3;
	reader: reader;
	queue: queue<any>;
	material_codes: {Huffman.code_struct<number>};
	closed: boolean;
	
	all: (self: deserializer_0)->();
	read_huffman_code: (self: deserializer_0)->(Enum.Material);
	reset: (self: deserializer_0)->();
	read_header: (self: deserializer_0)->();
} & iterator<any>

local Dash = require('./@roblox>Dash')

compose = Dash.compose
deserializer_0 = {}
deserializer_0.from = {}
lshift = bit32.lshift
bor = bit32.bor

function deserializer_0.new(reader: reader): deserializer_0
	local self: deserializer_0 = Object.simple.new(deserializer_0)
	
	self.result = {}
	self.reader = reader
	self.queue = Queue.default.new()
	
	
	return self
end

function deserializer_0.can_proceed(self: deserializer_0)
	return not self.closed
end

function deserializer_0.read_header(self: deserializer_0)
	assert(self.reader:readu32() == 0, 'Unsupported version')
end

function deserializer_0.reset(self: deserializer_0)
	self.closed = false
	self.result = {}
	self.voxel_spanning_size = nil
	self.material_codes = nil
end

function deserializer_0.read_huffman_code(self: deserializer_0)
	local reader = self.reader
	local code = 0 -- reader:read_bits(1)
	local structs = self.material_codes
	local bit_length = 0
	
	for _, struct in structs do
		while bit_length ~= struct.bit_length do
			bit_length += 1
			code = bor(lshift(code, 1), reader:read_bits(1))
		end
		
		if code == struct.canonical_code then
			return struct.symbol
		end
	end
end

function deserializer_0.proceed(self: deserializer_0)
	local reader = self.reader
	local result = self.result
	
	if not result.region_3 then
		local x, y, z = reader:readi32(), reader:readi32(), reader:readi32()
		local position = Vector3.new(x, y, z)
		
		x, y, z = reader:read_float(), reader:read_float(), reader:read_float()
		local size = Vector3.new(x, y, z)
		
		result.region_3 = Region3.new(position - (size / 2), position + (size / 2))
		return result.region_3
	end
	
	if not self.voxel_spanning_size then
		local x, y, z = reader:readu32(), reader:readu32(), reader:readu32()
		self.voxel_spanning_size = Vector3.new(x, y, z)
		return self.voxel_spanning_size
	end
	
	if not self.material_codes then
		local material_codes = {}
		
		local symbol = reader:readu32()
		
		while symbol ~= 0 do
			local bit_length = reader:readu8()
			table.insert(material_codes, {
				symbol = symbol,
				bit_length = bit_length,
			})
			symbol = reader:readu32()
		end
		
		Huffman.canonical.decompress(material_codes)
		
		for _, v in material_codes do
			v.symbol = Enum.Material:FromValue(v.symbol)
		end
		
		self.material_codes = material_codes
		
		return material_codes
	end
	
	local voxel_spanning_size = self.voxel_spanning_size
	
	if not result.materials then
		result.materials = {}
		result.materials.Size = voxel_spanning_size
	end
	
	local x, y, z = voxel_spanning_size.X, voxel_spanning_size.Y, voxel_spanning_size.Z
	local face = result.materials[x]
	local row = face and face[y]
	local element = row and row[z]
	local queue = self.queue
	
	if not element then
		if not queue:is_empty() then
			local element = queue:dequeue()
			array_3d.insert(result.materials, element)
			
			return element
		else
			local amount = reader:readu8()
			local material = self:read_huffman_code()
			
			if not material then
				print(amount)
			end
			assert(material)
			
			for i = 1, amount do
				queue:enqueue(material)
			end
			
			return self:proceed()
		end
	end
	
	if not result.occupancies then
		local term = reader:readu8()
	
		assert(term == 0, `expected terminator, got {term}`)
		
		result.occupancies = {}
		result.occupancies.Size = voxel_spanning_size
	end
	
	if not queue:is_empty() then
		local element = queue:dequeue()
		
		local test = result.occupancies[x]
		test = test and test[y]
		test = test and test[z]
		
		if test then
			print('at cap')
			print(result, element, queue)
		end
		
		array_3d.insert(result.occupancies, element)
		
		return element
	else
		local mode = reader:read_bits(1)
		
		if mode == 0 then
			local occupancy = reader:read_bits(1)
			local amount = reader:readu16()
			
			if occupancy == 0 and amount == 0 then
				self.closed = true
				reader:byte_align()
				return nil
			end
			
			for i = 1, amount do
				queue:enqueue(occupancy)
			end
		else
			local large = reader:readu16()
			local alpha = large / 0xFFFF
			
			queue:enqueue(alpha)
		end
		
		return self:proceed()
	end
end

deserializer_0.from.byte_iterator = compose(BinaryStream.msbit_reader.new, deserializer_0.new) :: (byte_iterator) -> deserializer_0

Class.make_proper_class(deserializer_0, '@CHL>TerrainFormat>deserializer_0')

struct_0.deserializer = deserializer_0

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

--[[
	in this approach, we attempt to serialize multiple structs into binary data as a length based array, in this case, we'll assume the formatting is deemed to be the following:
	
	u32 as the version
	u16 as the struct count
	rest of the data as the structs
]]

export type collection_serializer_0 = {
	collection: {struct_0};
	serializer: serializer_0;
	current: number;
} & byte_iterator

collection_serializer_0 = {}

function collection_serializer_0.new(collection: {struct_0}): collection_serializer_0
	local self: collection_serializer_0 = Object.simple.new(collection_serializer_0)
	
	self.collection = collection
	self.current = 1
	self.serializer = serializer_0.new(collection[1])
	
	self.serializer.writer:writeu32(0)
	self.serializer.writer:writeu16(#collection)
	self.serializer:header_write()
	
	return self
end

function collection_serializer_0.can_proceed(self: collection_serializer_0): number
	return 
		self.serializer:can_proceed() or 
		self.collection[self.current]
end

function collection_serializer_0.proceed(self: collection_serializer_0): number
	local serializer = self.serializer
	
	if not serializer.struct then
		serializer.struct = self.collection[self.current]
		serializer:header_write()
	end
	
	local result = serializer:proceed()
	
	if not serializer:can_proceed() then
		self.current += 1
		serializer.struct = nil
		serializer:reset()
		
		if self.current > #self.collection then
			serializer.closed = true
		end
	end
	
	return result
end

Class.make_proper_class(collection_serializer_0, '@CHL>TerrainFormat>collection_serializer_0')

struct_0.collection_serializer = collection_serializer_0

--########################################################################################################################################################################################
--########################################################################################################################################################################################
--########################################################################################################################################################################################

export type collection_deserializer_0 = {
	collection: {struct_0};
	deserializer: deserializer_0;
	length: number;
	current: number;
} & iterator<any>

collection_deserializer_0 = {}

function collection_deserializer_0.new(deserializer: deserializer_0): collection_deserializer_0
	local self: collection_deserializer_0 = Object.simple.new(collection_deserializer_0)
	
	assert(deserializer.reader:readu32() == 0)
	
	self.deserializer = deserializer
	self.collection = {}
	self.length = deserializer.reader:readu16()
	self.current = 1
	
	print(self)
	
	deserializer:read_header()
	
	return self
end

function collection_deserializer_0.can_proceed(self: collection_deserializer_0): boolean
	return 
		self.deserializer:can_proceed() or 
		not self.collection[self.length]
end

function collection_deserializer_0.proceed(self: collection_deserializer_0): any
	if not self:can_proceed() then
		return nil
	end
	
	local deserializer = self.deserializer
	
	local result = deserializer:proceed()
	
	if not deserializer:can_proceed() then
		self.collection[self.current] = deserializer.result
		self.current += 1
		
		if self:can_proceed() then
			deserializer:reset()
			deserializer:read_header()
		end
	end
	
	return result
end

collection_deserializer_0.from_reader = compose(deserializer_0.new, collection_deserializer_0.new) :: (reader) -> collection_deserializer_0
collection_deserializer_0.from_byte_iterator = compose(deserializer_0.from.byte_iterator, collection_deserializer_0.new) :: (reader) -> collection_deserializer_0

Class.make_proper_class(collection_deserializer_0, '@CHL>Terrain>collection_deserializer_0')

struct_0.collection_deserializer = collection_deserializer_0

return module
