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
local Objects = script.Parent

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

module.char = {}

function module.char.is_printable(c: string)
	local byte = c:byte()

	return byte >= 32 and byte < 127
end

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
		print(tokens)
	for i, v in tokens do
		local found = v:match('^\\(%d+)$') 
		local succeeding = tokens[i + 1]
		if not (found and succeeding and succeeding:match('^%d+$')) then 
			print(i, found, succeeding)
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

Iterator = {}

function Iterator.init_simple(s: string)
	return Iterator.simple, s, 0
end

function Iterator.simple(s: string, i: number)
	i += 1
	if i > #s then return;end
	return i, s:sub(i,i)
end

module.Iterator = Iterator

--#########################################################################################
--#########################################################################################
--#########################################################################################

return module
