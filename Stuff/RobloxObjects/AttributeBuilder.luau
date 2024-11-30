local Objects = script.Parent
local Map = require(Objects["@CHL/Map"])
local BufferWrapper = require(Objects["@CHL/BufferWrapper"])
local BinaryTypes = require(Objects["@CHL/RobloxBinaryDataTypes"])

export type attributes = Map.dictionary<any>;

local module = {}

buffer_extended = BufferWrapper.extended

module.from = {}
module.value_types = {
	[0x02] = 'string';
	[0x03] = 'boolean';
	[0x06] = 'float64';
	[0x09] = 'udim';
	[0x0A] = 'udim2';
	[0x0E] = 'brickcolor';
	[0x0F] = 'color3f';
	[0x10] = 'vector2';
	[0x11] = 'vector3';
	[0x14] = 'cframe';
}

function module.from.buffer(b: buffer)
	local result = {}
	
	if buffer.len(b) == 0 then
		return result
	end
	
	local len = buffer.readu32(b, 0)

	local j = 4
	
	for i = 1, len do
		local index
		j, index = BinaryTypes.data_types.string(b, j)
		
		local v_type = buffer.readu8(b, j)
		j+=1
		local v_index = assert(
			module.value_types[v_type], 
			`Attempting to use undefined value types: expected \z
			proper value, got {v_type} ({("%02X"):format(v_type)})`
		)
		local v_function = assert(
			BinaryTypes.data_types[v_index],
			`Attempting to use non-existant function: expected \z
				proper function, got: {v_index}`
		)
		local value
		j, value = v_function(b, j)
		
		result[index] = value
	end
	

	return result
end

function module.from.string(s: string)
	return module.from.buffer(buffer.fromstring(s))
end

return module
