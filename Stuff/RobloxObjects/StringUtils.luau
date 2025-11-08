--// TYPES
export type multiline_type = 'single' | 'multiline'
export type single_line_tokens = '"' | "'"

export type lua_string_args = {
	multiline_type: multiline_type;
	token: single_line_tokens?;
	equal_signs_amount: number?;
	prefix: string?;
	suffix: string?;
}

--// MAIN
local module = {}

disguise = require('./LuaUTypes').disguise
insert = table.insert

--#########################################################################################
--#########################################################################################
--#########################################################################################

function module.is_sugar_index(i: string) return not not i:match('^[%a_][%w_]*$') end
function module.to_camel_case(s: string)return s:sub(1,1):lower() .. s:sub(2)end

function module.compare_strings(operand_a: string, operand_b: string): boolean
	-- pre
	assert(
		type(operand_a) == 'string' and 
			type(operand_b) == 'string'
	)

	-- main
	local result = false
	local lStr = #operand_a > #operand_b and operand_a or operand_b

	for i = 1, #lStr do
		local cA = operand_a:sub(i, i)
		local cB = operand_b:sub(i, i)
		local vA = cA == '' and -1 or cA:byte()
		local vB = cB == '' and -1 or cB:byte()

		if vA ~= vB then
			result = vA < vB
			break
		end
	end

	return result
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

local Set = require('./@CHL>Set')

export type char_set = Set.simple<string>

module.char = {}

function per_char_in_range(s: string, f: (c: string)->())
	local a, b = s:byte(1, 2)
	
	for i = a, b do
		f(string.char(i))
	end
end

function module.char.is_printable(c: string)
	local byte = c:byte()

	return byte >= 32 and byte < 127
end

module.char.digits = {} :: char_set
module.char.alpha_lower = {} :: char_set
module.char.alpha_upper = {} :: char_set
module.char.alpha = {} :: char_set

per_char_in_range('09', function(a)
	module.char.digits[a] = true
end)

per_char_in_range('az', function(a)
	local b = a:upper()

	module.char.alpha_lower[a] = true
	module.char.alpha_upper[b] = true
	module.char.alpha[a] = true
	module.char.alpha[b] = true
end)
--#########################################################################################
--#########################################################################################
--#########################################################################################

module.lua_string = {}

--[[
	Takes in a raw string and explicit assigned args, then returns a list of tokens in string
]]
function module.lua_string.to_tokens(str: string, args: lua_string_args): {string}
	local result = str:split''
	insert(result, 1, args.prefix)
	
	local i = 2
	
	while i <= #result do
		local v = result[i]

		if args.multiline_type == 'single' then
			local token = nil;
			
			if v == args.suffix then
				token = `\\{v}`
			elseif v == '\n' then
				token = '\\n'
			elseif v == '\\' then
				token = '\\\\'
			elseif not module.char.is_printable(v) then
				token = `\\{v:byte()}`
			end
			
			if token then
				result[i] = token
			end
			
		elseif v == ']' then
			local j = i
			repeat
				i += 1
			until result[i] ~= '='
			
			if i - j - 1 == args.equal_signs_amount then
				result[i] = '\\]'
			end
		end
		
		i += 1
	end
	
	insert(result, args.suffix)
	return result
end

--[[
	Takes in a raw string and implict assigned args, then returns a lua formatted string
]]
function module.lua_string.from_raw(str: string, args: lua_string_args?)
	-- pre
	local a = disguise(args or {})::lua_string_args
	a.multiline_type = a.multiline_type or 'single'
	a.equal_signs_amount = a.equal_signs_amount or 0
	a.token = a.token or '\''
	
	if a.multiline_type == 'single' then
		a.prefix = a.token
		a.suffix = a.token
	else
		local s = ('='):rep(a.equal_signs_amount)
		a.prefix = `[{s}[`
		a.suffix = `]{s}]`
	end
	
	-- main
	local tokens = module.lua_string.to_tokens(str, a)
	for i, v in tokens do
		local found = v:match('^\\(%d+)$') 
		local succeeding = tokens[i + 1]
		if not (found and succeeding and succeeding:match('^%d+$')) then 
			continue
		end
		
		tokens[i]..='\\z';
	end
	
	return table.concat(tokens)
end

function module.to_sugar_index(i: string, args: lua_string_args?)
	if module.is_sugar_index(i) then return i;end
	if typeof(i) == 'string' then
		i = module.lua_string.from_raw(i, args)
	end
	return `[{i}]`
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

local Iterator = require('./@CHL>Iterator')

s_iterator = {}

function s_iterator.init_simple(s: string)
	return s_iterator.simple, s, 0
end

function s_iterator.simple(s: string, i: number)
	i += 1
	if i > #s then return;end
	return i, s:sub(i,i)
end

module.iterator = s_iterator

--#########################################################################################
--#########################################################################################
--#########################################################################################

-- byte iterator

local Object = require('./Object')
local Class = require('./Class')

type simple_it<T, U...> = Iterator.simple<T, U...>
export type byte_iterator = {
	referral: string;
	i: number;
} & simple_it<number>

b_iterator = {}

function b_iterator.new(s: string, i: number?): byte_iterator
	local self: byte_iterator = Object.simple.new(b_iterator)
	self.referral = s;
	self.i = i or 1
	return self
end

function b_iterator.can_proceed(self: byte_iterator)
	return not not self.referral:byte(self.i)
end

function b_iterator.proceed(self: byte_iterator)
	if not self:can_proceed() then return;end
	
	local result = self.referral:byte(self.i)
	
	self.i += 1
	
	return result
end

b_iterator.__iter = Iterator.simple.__iter
Class.makeProperClass(b_iterator, '@CHL>StringUtils>Iterator>Byte')

module.iterator.byte = b_iterator

--#########################################################################################
--#########################################################################################
--#########################################################################################

export type char_iterator = {
	byte_it: byte_iterator;
} & simple_it<string>

c_iterator = {}
c_iterator.from = {}

function c_iterator.new(byte_it: byte_iterator):char_iterator
	local self: char_iterator = Object.simple.new(c_iterator)
	self.byte_it = byte_it
	return self
end

function c_iterator.from.string(s: string, i: number?): char_iterator
	return c_iterator.new(b_iterator.new(s, i))
end

function c_iterator.can_proceed(self: char_iterator)
	return self.byte_it:can_proceed()
end

function c_iterator.proceed(self: char_iterator)
	if not self:can_proceed() then return;end

	local result = self.byte_it:proceed()
	
	if result then
		result = string.char(result)
	end

	return result
end

c_iterator.__iter = Iterator.simple.__iter
Class.makeProperClass(c_iterator, '@CHL>StringUtils>Iterator>Char')

module.iterator.char = c_iterator

--#########################################################################################
--#########################################################################################
--#########################################################################################

return module
