--[[
	serializer and deserializer for plugin settings api
	
	for this serializer, data is stored as a base64 string, when decompressed it becomes a series of indicators and values, all read little endian

	the first four bytes are a uint which describe the version
	
	this section describes version 0
	
	version 0 has a collection of indicators, which are deemed to be all ubytes
	
	+---+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	|val|description                                                                                                                                                                   |
	+---+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	|0  |terminator, specifically it terminates a collection, such as an array or struct                                                                                               |
	|1  |ubyte length string, where the format is the length type, then the characters                                                                                                 |
	|2  |ushort length string                                                                                                                                                          |
	|3  |uint length string                                                                                                                                                            |
	|4  |ubyte                                                                                                                                                                         |
	|5  |ushort                                                                                                                                                                        |
	|6  |uint                                                                                                                                                                          |
	|7  |ulong                                                                                                                                                                         |
	|8  |ibyte                                                                                                                                                                         |
	|9  |ishort                                                                                                                                                                        |
	|10 |int (signed)                                                                                                                                                                  |
	|11 |long (signed)                                                                                                                                                                 |
	|12 |float                                                                                                                                                                         |
	|13 |double                                                                                                                                                                        |
	|14 |boolean, represented as one bit                                                                                                                                               |
	|15 |array of values, to represent this, an array of indicator-type values is used, however, seeing potential for compression, there is also another indicator indicating the type,|
	|   |if the type is 0, then the array is dynamic typed and requires all entries be indicator typed, non-0 types have not been implemented yet                                      |
	|16 |struct of values, which is simply a map, indices and values are deemed to be indicator-type values, same as before, where we consider the possibility of accounting for       |
	|   |explicit types                                                                                                                                                                |
	+---+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

]]

local Iterator = require('./@CHL>Iterator')
local BinaryStream = require('./@CHL>BinaryStream')
local Class = require('./Class')
local Object = require('./Object')
local Stack = require('./@CHL>LinkedStack')
local Queue = require('./@CHL>LinkedQueue')
local Map = require('./@CHL>Map')


type map<I,V> = Map.simple<I, V>
type queue<T> = Queue.object<T>
type stack<T> = Stack.object<T>
export type reader = BinaryStream.msbit_reader
export type writer = BinaryStream.msbit_writer


local module = {}

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

versions = {}
versions.v_0 = {}
versions.v_0.value_structs = {}

versions.v_0.value_structs[1] = {}
versions.v_0.value_structs[1].serialize = function<T>(serializer_0: serializer_0<T>, value: string)
	serializer_0.writer:writeu8(#value)
	serializer_0.writer:write_string(value)
end
versions.v_0.value_structs[1].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	local length = deserializer_0.reader:readu8()
	local value = deserializer_0.reader:read_string(length)
	return value
end

versions.v_0.value_structs[2] = {}
versions.v_0.value_structs[2].serialize = function<T>(serializer_0: serializer_0<T>, value: string)
	serializer_0.writer:writeu16(#value)
	serializer_0.writer:write_string(value)
end
versions.v_0.value_structs[2].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	local length = deserializer_0.reader:readu16()
	local value = deserializer_0.reader:read_string(length)
	return value
end

versions.v_0.value_structs[3] = {}
versions.v_0.value_structs[3].serialize = function<T>(serializer_0: serializer_0<T>, value: string)
	serializer_0.writer:writeu32(#value)
	serializer_0.writer:write_string(value)
end
versions.v_0.value_structs[3].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	local length = deserializer_0.reader:readu32()
	local value = deserializer_0.reader:read_string(length)
	return value
end

versions.v_0.value_structs[4] = {}
versions.v_0.value_structs[4].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writeu8(value)
end
versions.v_0.value_structs[4].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readu8()
end

versions.v_0.value_structs[5] = {}
versions.v_0.value_structs[5].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writeu16(value)
end
versions.v_0.value_structs[5].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readu16()
end

versions.v_0.value_structs[6] = {}
versions.v_0.value_structs[6].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writeu32(value)
end
versions.v_0.value_structs[6].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readu32()
end

versions.v_0.value_structs[7] = {}
versions.v_0.value_structs[7].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writeu64(value)
end
versions.v_0.value_structs[7].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readu64()
end

versions.v_0.value_structs[8] = {}
versions.v_0.value_structs[8].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writei8(value)
end
versions.v_0.value_structs[8].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readi8()
end

versions.v_0.value_structs[9] = {}
versions.v_0.value_structs[9].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writei16(value)
end
versions.v_0.value_structs[9].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readi16()
end

versions.v_0.value_structs[10] = {}
versions.v_0.value_structs[10].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writei32(value)
end
versions.v_0.value_structs[10].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readi32()
end

versions.v_0.value_structs[11] = {}
versions.v_0.value_structs[11].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	error('unimplemented')
end
versions.v_0.value_structs[11].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	error('unimplemented')
end

versions.v_0.value_structs[12] = {}
versions.v_0.value_structs[12].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writef32(value)
end
versions.v_0.value_structs[12].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readf32()
end

versions.v_0.value_structs[13] = {}
versions.v_0.value_structs[13].serialize = function<T>(serializer_0: serializer_0<T>, value: number)
	serializer_0.writer:writef64(value)
end
versions.v_0.value_structs[13].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:readf64()
end

versions.v_0.value_structs[14] = {}
versions.v_0.value_structs[14].serialize = function<T>(serializer_0: serializer_0<T>, value: boolean)
	serializer_0.writer:write_bits(value and 1 or 0, 1)
end
versions.v_0.value_structs[14].deserialize = function<T>(deserializer_0: deserializer_0<T>)
	return deserializer_0.reader:read_bits(1) == 1
end

versions.v_0.value_structs[15] = {}
versions.v_0.value_structs[15].serialize = function<T>(serializer_0: serializer_0<T>, value: {any}, top: any)
	local writer = serializer_0.writer
	local stack = serializer_0.stack
	
	if not top then
		writer:writeu8(0) -- no explicit type
		
		serializer_0.stack:push({
			parse_type = 'array';
			value = value;
			index = next(value);
			explicit_type = 15;
		})
	else
		local t_value = value[top.index]
		
		top.index = next(value, top.index)
		
		if not top.index then
			stack:push({
				parse_type = 'closure';
			})
		else
			stack:push(top)
		end
		
		stack:push({
			parse_type = 'value';
			value = t_value;
			explicit_type = serializer_0.classify(t_value)
		})
	end
end
versions.v_0.value_structs[15].deserialize = function<T>(deserializer_0: deserializer_0<T>, top: any)
	local reader = deserializer_0.reader
	local stack = deserializer_0.stack
	
	if not top.value then
		assert(reader:readu8() == 0, 'invalid explicit type')
		
		top = {}
		
		top.explicit_type = 15
		top.value = {}
		top.index = 1
	end
	
	stack:push(top)
	
	local next_indicator = reader:readu8()
	
	if next_indicator == 0 then
		stack:pop()
	else
		stack:push({
			onto = top.value;
			index = top.index;
			explicit_type = next_indicator
		})
		
		top.index += 1
	end
	
	return top.value
end

versions.v_0.value_structs[16] = {}
versions.v_0.value_structs[16].serialize = function<T>(serializer_0: serializer_0<T>, value: {any}, top: any)
	local writer = serializer_0.writer
	local stack = serializer_0.stack
	
	if not top then
		writer:writeu8(0)
		writer:writeu8(0)
		
		stack:push({
			parse_type = 'struct';
			value = value;
			index = next(value);
			explicit_type = 16;
		})
	else
		local index = top.index
		local t_value = value[index]
		
		top.index = next(value, index)
		
		if not top.index then
			stack:push({
				parse_type = 'closure';
			})
		else
			stack:push(top)
		end
		
		stack:push({
			parse_type = 'value';
			value = t_value;
			explicit_type = serializer_0.classify(t_value)
		})
		
		stack:push({
			parse_type = 'value';
			value = index;
			explicit_type = serializer_0.classify(index)
		})
	end
end
versions.v_0.value_structs[16].deserialize = function<T>(deserializer_0: deserializer_0<T>, top: any)
	local reader = deserializer_0.reader
	local stack = deserializer_0.stack
	
	if not top.value then
		assert(reader:readu8() == 0, 'invalid explicit index type')
		assert(reader:readu8() == 0, 'invalid explicit value type')
		
		top = {}
		
		top.explicit_type = 16
		top.value = {}
	end
	
	stack:push(top)
	
	local next_indicator = reader:readu8()
	
	if not top.index then
		if next_indicator == 0 then
			stack:pop()
		else
			stack:push({
				onto = top;
				index = 'index';
				explicit_type = next_indicator
			})
		end
	else
		stack:push({
			onto = top.value;
			index = top.index;
			explicit_type = next_indicator
		})
		
		top.index = nil
	end
	
	return top.value
end

module.versions = {}

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

export type serializer_0<T = any> = {
	writer: writer;
	reference: T;
	stack: stack<any>;
	bytes: queue<number>;
	explicit_type: number;
	reference_is_table: boolean;
	
	destroy: (self: serializer_0<T>) -> ();
} & Iterator.simple<number>

serializer_0 = {}

function serializer_0.new<T>(reference: T, explicit_type: number?): serializer_0<T>
	local self: serializer_0<T> = Object.simple.new(serializer_0)
	
	self.reference = reference
	self.reference_is_table = typeof(reference) == 'table'
	self.writer = BinaryStream.writer.new({consume=function(_, byte)
		self.bytes:enqueue(byte)
	end})
	self.bytes = Queue.default.new()
	self.stack = Stack.new()
	
	self.stack:push({
		parse_type = 'value';
		value = reference; 
		explicit_type = explicit_type or serializer_0.classify(reference)
	})
	
	self.explicit_type = explicit_type
	
	self.writer:writeu32(0x0000_0000)
	
	return self
end

function serializer_0.can_proceed<T>(self: serializer_0<T>): boolean
	return not self.bytes:is_empty() or not self.stack:is_empty()
end

function serializer_0.proceed<T>(self: serializer_0<T>): number
	local stack = self.stack
	local queue = self.bytes
	local writer = self.writer
	local result
	
	if not queue:is_empty() then
		result = queue:dequeue()
		
		return result
	end
	
	if not stack:is_empty() then
		local top = stack:pop()
		
		if top.parse_type == 'closure' then
			writer:writeu8(0)
		else
			local struct = versions.v_0.value_structs[top.explicit_type]
			
			assert(struct)
			
			if top.parse_type == 'value' then
				writer:writeu8(top.explicit_type)
				struct.serialize(self, top.value)
			elseif struct then
				struct.serialize(self, top.value, top)
			end
		end
		
		if self:can_proceed() then
			return self:proceed()
		end
	end
	
	return result
end

function serializer_0.destroy<T>(self: serializer_0<T>)
	self.writer.consumer = nil
	table.clear(self)
	self.is_destroyed = true
end

function serializer_0.number_classify(v: number): number
	local is_int = v % 1 == 0
	
	if is_int then
		local is_natural = math.sign(v) == 1 or v == 0
		
		if is_natural then
			if v <= 0xFF then
				return 4
			elseif v <= 0xFFFF then
				return 5
			elseif v <= 0xFFFF_FFFF then
				return 6
			else
				return 7
			end
		else
			v = -v
			
			if v <= 0x80 then
				return 8
			elseif v <= 0x8000 then
				return 9
			elseif v <= 0x8000_0000 then
				return 10
			else
				return 11
			end
		end
	else
		-- 12 is deemed to be a 32 bit float, atm idk how to check for that
		return 13
	end
end

function serializer_0.table_info_of(t: map<any, any>)
	local is_array = true
	local result = {}
	local expected = 1
	
	for i, v in t do
		if i ~= expected then
			is_array = false
			break
		else
			expected += 1
		end
	end
	
	result.is_array = is_array
	
	return result
end

function serializer_0.classify(v: any): number
	local v_type = typeof(v)
	
	if v_type == 'string' then
		local length = #v
		local num_class = serializer_0.number_classify(length)
		
		if num_class == 7 --[[ulong]] then
			error('oddly long string (length deemed as ulong)')
		end
		
		return num_class - 3 -- nth len string
	elseif v_type == 'number' then
		return serializer_0.number_classify(v)
	elseif v_type == 'boolean' then
		return 14
	elseif v_type == 'nil' then
		error('nil is never stored')
	elseif v_type == 'table' then
		local info = serializer_0.table_info_of(v)
		
		if info.is_array then
			return 15
		else
			return 16
		end
	end
end

Class.make_proper_class(serializer_0, '@CHL>PluginSetting>Serializer0')

module.serializer_0 = serializer_0

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################

export type deserializer_0<T = any> = {
	reader: reader;
	result: T;
	stack: stack<any>;
	
	all: (self: deserializer_0<T>) -> T;
	parse_indicator_type_pair: (self: deserializer_0<T>) -> (number, any);
} & Iterator.simple<any>

local Dash = require('./@roblox>Dash')

deserializer_0 = {}
compose = Dash.compose

function deserializer_0.new<T>(reader: reader): deserializer_0<T>
	local self: deserializer_0<T> = Object.simple.new(deserializer_0)
	
	self.reader = reader
	self.stack = Stack.new()
	
	self.stack:push({
		parse_type = 'value';
		onto = self;
		index = 'result';
	})
	
	assert(reader:readu32() == 0)
	
	return self
end

function deserializer_0.all<T>(self: deserializer_0<T>): T
	while self:can_proceed() do
		self:proceed()
	end
	
	return self.result
end

function deserializer_0.can_proceed<T>(self: deserializer_0<T>): T
	return not self.stack:is_empty()
end

function deserializer_0.parse_indicator_type_pair<T>(self: deserializer_0<T>, arg): (number, any)
	local indicator_type = arg.explicit_type or self.reader:readu8()
	local value
	
	if indicator_type ~= 0 then
		local struct = versions.v_0.value_structs[indicator_type]
		
		assert(struct)
		
		value = struct.deserialize(self, arg)
	end
	
	return indicator_type, value
end

function deserializer_0.proceed<T>(self: deserializer_0<T>): T
	local stack = self.stack
	local top = stack:pop()
	local indicator, value
	
	indicator, value = self:parse_indicator_type_pair(top)
	
	if top.onto then
		top.onto[top.index] = value
	end
	
	return value
end

deserializer_0.from = {}
deserializer_0.from.byte_iterator = compose(BinaryStream.msbit_reader.new, deserializer_0.new) :: (Iterator.simple<number>) -> deserializer_0

deserializer_0.run_process = compose(deserializer_0.from.byte_iterator, deserializer_0.all) :: <T>(Iterator.simple<number>) -> T


Class.make_proper_class(deserializer_0, '@CHL>PluginSetting>Deserializer0')

module.deserializer_0 = deserializer_0

--##########################################################################################################################################################################################
--##########################################################################################################################################################################################
--##########################################################################################################################################################################################


return module
