--###########################################################################################################################################################################
--###########################################################################################################################################################################
--###########################################################################################################################################################################

local StringUtils = require('./@CHL>StringUtils')
local Dash = require('./@roblox>Dash')
local Set = require('./@CHL>Set')
local Map = require('./@CHL>Map')

export type forward = {
	depth: number;
	table_options: options;
	accessed: Set.simple<Map.simple<any, any>>;
	
	parse_to_lines: (self: forward, v: any, options?) -> {string};
	parse: (self: forward, v: any, options) -> string;
	clear_accessed: (self: forward) -> ();
	reset: (self: forward) -> ();
}

export type options = {
	max_depth: number?;
	indent_unit: string | '\t';
	string_args: StringUtils.lua_string_args?;
}

--// MAIN
local module = {}
local LuaUTypes = require('./LuaUTypes')
local TableUtils = require('./@CHL>TableUtils')
local Object = require('./Object')
local Class = require('./Class')

disguise = LuaUTypes.disguise
push = TableUtils.push
defaultify = TableUtils.defaultify
forward = {} -- parses raw to formatted

forward.default_options = {
	max_depth = 10;
	indent_unit = '\t';
	string_args = {
		token = '\'';
		multiline_type = 'single';
	}
} :: options

function forward.new(options: options?): forward
	local self: forward = Object.simple.new(forward)
	
	self.table_options = defaultify(options, forward.defaultOptions)
	self.accessed = {}
	self.depth = 1
	
	return self
end

function forward.parse_to_lines(self: forward, v: any, op: options): {string}
	-- pre
	op = TableUtils.defaultify(op, self.table_options)
	
	-- main
	if typeof(v) == 'table' then
		-- case of deep
		if self.depth > op.maxDepth then
			return {'* Max depth reached *'}
		end
		
		-- case of accessed
		if self.accessed[v] then return {'* Cyclic referencing reached *'}end
		
		-- case of metatable
		local meta = getmetatable(v) :: LuaUTypes.metatable<typeof(v)>?
		
		if meta and meta.__tostring then return tostring(v):split('\n') end
		
		-- case of empty
		if TableUtils.isEmpty(v) then return {'{}'}end
		
		-- other cases
		local result = {'{'}
		local isProperArray = TableUtils.isProperArray(v)

		self.accessed[v] = true
		
		for i: string, w: any in next, v do
			-- index
			if not isProperArray then
				i = `{StringUtils.sugarfy(i, op.stringArgs)} = `
			else
				i = ''
			end
			
			-- value
			self.depth += 1
			
			local wLines = self:parse_to_lines(w, op)
			
			self.depth -= 1
			
			wLines[1] = `{op.indentUnit}{i}{wLines[1]}`
			
			for i = 2, #wLines do
				wLines[i] = op.indentUnit .. wLines[i]
			end
			
			wLines[#wLines] = Dash.last(wLines) .. (isProperArray and ',' or ';')
			
			Dash.append(result, wLines)
		end
		
		return push(result, '}')
	elseif typeof(v) == 'string' then
		return {StringUtils.luaStringify(v, op.stringArgs)}
	end
	return {tostring(v)}
end

function forward.parse(self: forward, v: any, override): string
	return table.concat(self:parse_to_lines(v, override), '\n')
end

function forward.clear_accessed(self:forward)table.clear(self.accessed)end

function forward.reset(self: forward) self:clear_accessed()self.depth = 1 end

Class.make_proper_class(forward, '@CHL>StringifyCompiler>Forward')

module.forward = forward

--###########################################################################################################################################################################
--###########################################################################################################################################################################
--###########################################################################################################################################################################

local Iterator = require('./@CHL>Iterator')

export type reverse_token_type = 'delimiter' | 'escape' | 'raw' | 'error'

export type reverse_token = {
	reverse_token_type: reverse_token_type;
	value: string;
}

export type reverse = {
	input: Iterator.simple<string>;
	did_beginning_delimiter: boolean;
	explicit_close: boolean;
	delimiter: string;
	error_token: reverse_token?;
	
	error_close: (self: reverse, value: string) -> ();
	to_list: (self: reverse) -> {reverse_token};
	to_string_list: (self: reverse) -> {string};
	to_raw_string: (self: reverse) -> string;
} & Iterator.simple<reverse_token>

reverse = {}
compose = Dash.compose

function reverse.new(input: Iterator.simple<string>): reverse
	local self: reverse = Object.simple.new(reverse)
	
	self.input = input
	self.delimiter = '<NO_DELIMITER>'
	
	return self
end

function reverse.can_proceed(self: reverse): boolean return not self.explicit_close end

function reverse.error_close(self: reverse, value: string)
	self.error_token = {
		reverse_token_type = 'error';
		value = value;
	}
end

function reverse.proceed(self: reverse): reverse_token
	if self.error_token then
		self.explicit_close = true
		return self.error_token
	end
	
	local input = self.input
	
	if not self.did_beginning_delimiter then
		local char = input:proceed()
		
		if char == '[' then
			return self:error_close('unhandled beginning delimiter: [')
		end
		
		self.delimiter = char
		self.did_beginning_delimiter = true
		
		return {
			reverse_token_type = 'delimiter';
			value = char;
		}
	end
	
	if not input:can_proceed() then
		self:error_close('failed to terminate lua string')
		return self:proceed()
	end
	
	local char = input:proceed()
	
	if char == self.delimiter then
		self.explicit_close = true
		
		return {
			reverse_token_type = 'delimiter';
			value = char;
		}
	elseif char == '\\' then
		if not input:can_proceed() then
			self:error_close('failed to read escape sequence')
			return self:proceed()
		end
		
		local escaped_char = input:proceed()
		
		if escaped_char:lower() == 'x' then
			local hex_char_1, hex_char_2 -- validation for hex characters later
			
			if not input:can_proceed() then
				self:error_close('failed to read hex escape sequence, character 1')
				return self:proceed()
			end
			
			hex_char_1 = input:proceed()
			
			if not input:can_proceed() then
				self:error_close('failed to read hex escape sequence, character 2')
				return self:proceed()
			end
			
			hex_char_2 = input:proceed()
			
			return {
				reverse_token_type = 'escape';
				value = `\\x{hex_char_1}{hex_char_2}`
			}
		else
			return {
				reverse_token_type = 'escape';
				value = `\\{escaped_char}`
			}
		end
	else
		return {
			reverse_token_type = 'raw';
			value = char;
		}
	end
end

function reverse.to_list(self: reverse)
	local result = {}
	
	while self:can_proceed() do
		table.insert(result, self:proceed())
	end
	
	return result
end


function reverse.to_string_list(self: reverse)
	local result = {}
	
	while self:can_proceed() do
		table.insert(result, self:proceed().value)
	end
	
	return result
end

reverse.all = {}
reverse.to_raw_string = compose( reverse.to_string_list, table.concat )
reverse.from_lua_string = compose( StringUtils.iterator.char.from.string, reverse.new ) :: (input: string) -> reverse
reverse.all.lua_string_to_raw_string = compose( reverse.from_lua_string, reverse.to_raw_string ) :: (input: string) -> string
reverse.all.lua_string_to_list = compose( reverse.from_lua_string, reverse.to_list ) :: (input: string) -> {reverse_token}

Class.make_proper_class(reverse, '@CHL>StringifyCompiler>Reverse')

module.reverse = reverse

--###########################################################################################################################################################################
--###########################################################################################################################################################################
--###########################################################################################################################################################################

return module
