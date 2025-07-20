local Class = require('./Class')
local Object = require('./Object')
local Dash = require('./@CHL>DashSingular')
local C_op = require('./@CHL>ComposeOperations')

export type byte_list = {number}

export type object = {
	prefix: byte_list;
	suffix: byte_list;
	
	to_indices_list: (self: object, number)->{number};
	to_byte_list: (self: object, number)->byte_list;
	to_variable: (self: object, number)->string;
} & Object.object_inheritance

local module = {}

module.from = {}

function list_chars(str: string): string
	local result = {}

	for i = str:byte(), str:byte(2) do
		table.insert(result, i)
	end

	return string.char(unpack(result))
end

function module.new(prefix: byte_list, suffix: byte_list): object
	local self: object = Object.from.class(module)
	
	self.prefix = prefix
	self.suffix = suffix
	
	return self
end

function module.from.strings(prefix: string, suffix: string)
	return module.new(
		Dash.map(prefix:split(''), string.byte),
		Dash.map(suffix:split(''), string.byte)
	)
end

function module.to_indices_list(self: object, i: number)
	local n_p = #self.prefix
	local n_s = #self.suffix
	local suffix_length = 0
	
	local range = n_p
	
	-- evaluate how long the suffix part of variable is, correct i to ensure uniqueness
	while range <= i do
		suffix_length += 1
		i -= range
		range *= n_s
	end

	local result = table.create(suffix_length + 1, 0)

	-- now evaluate for the suffix, the suffix always has the same base
	for j = 1, suffix_length do
		local index = i % n_s
		i = (i - index) // n_s
		result[suffix_length - j + 2] = index
	end

	-- therefore whatever is left for i is always the prefix index
	result[1] = i

	return result
end

function module.to_byte_list(self: object, i: number)
	local result = self:to_indices_list(i)
	
	result[1] = self.prefix[result[1]]
	
	for i = 2, #result do
		result[i] = self.suffix[result[i]]
	end
	
	return result
end

module.to_string = Dash.compose(
	module.to_byte_list,
	C_op.append_argument(string.char),
	Dash.map,
	table.concat
)

Class.makeProperClass(module, '@CHL>ProceduralVariable')

local prefix = list_chars('az') .. list_chars('AZ') .. '_'
local suffix = prefix .. list_chars('09')

module.luau = module.from.strings(prefix, suffix)

return module
