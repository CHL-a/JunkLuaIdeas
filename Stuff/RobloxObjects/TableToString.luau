local module = {}

--#################################################################################################################################################
--#################################################################################################################################################
--#################################################################################################################################################

local Map = require('./@CHL>Map')
local Iterator = require('./@CHL>Iterator')
local TableUtils = require('./@CHL>TableUtils')
local StringUtils = require('./@CHL>StringUtils')

type map<I,V> = Map.simple<I, V>
type any_map = map<any, any>
type simple_iterator<A, B...> = Iterator.simple<A, B...>
type table_type = TableUtils.table_type

export type token_type = '{' | '}' | '=' | '[' | ']' | 'value' | 'index' | 'delimiter'

export type token = {
	token_type: token_type;
	value: any;
	is_sugar_index: boolean?;
}

export type lexer = {
	referral: any_map;
	queue: {token};
	current_index: any;
	completed_all_entries: boolean;
	table_type: table_type;
	
	enqueue_token: (self: lexer, token_type, value: string?)->token;
} & simple_iterator<token>

local Object = require('./Object')
local Class = require('./Class')

Lexer = {}
tremove = table.remove

function Lexer.new(referral: any_map): lexer
	local self: lexer = Object.simple.new(Lexer)
	
	self.referral = referral
	self.queue = {}
	self.table_type = TableUtils.get_type(referral)
	
	if self.table_type == 'odd' then
		print(self.referral)
		error('unable to implement table of type odd')
	end
	
	self:enqueue_token('{')
	
	return self
end

function Lexer.enqueue_token(self: lexer, token_type, value)
	local result = {
		token_type = token_type;
		value = value or token_type;
	}
	
	table.insert(self.queue, result)
	
	return result
end

function Lexer.can_proceed(self: lexer)
	return not self.completed_all_entries or #self.queue > 0
end

function Lexer.proceed(self: lexer)
	if not self:can_proceed() then
		return
	end
	
	if #self.queue > 0 then
		return tremove(self.queue, 1)
	end
	
	local index = next(self.referral, self.current_index)
	
	
	if not index then
		self.completed_all_entries = true
		self:enqueue_token('}')
	else
		local value = self.referral[index]
		
		-- index tokens
		if self.table_type ~= 'array' then
			local is_sugar_index = typeof(index) == 'string' and StringUtils.is_sugar_index(index)
			
			if not is_sugar_index then
				self:enqueue_token('[')
			end
			
			local index_token = self:enqueue_token('index', index)
			index_token.is_sugar_index = is_sugar_index

			if not is_sugar_index then
				self:enqueue_token(']')
			end

			self:enqueue_token('=')
		end
		
		-- value tokens
		self:enqueue_token('value', value)
		
		-- delimiter
		if next(self.referral, index) ~= nil then
			if self.table_type == 'array' then
				self:enqueue_token('delimiter', ',')
			else
				self:enqueue_token('delimiter', ';')
			end
		end
		
		self.current_index = index
	end
	
	return tremove(self.queue, 1)
end

Iterator.simple.declare_as(Lexer)
Class.make_proper_class(Lexer, '@CHL>TableToString>Lexer')

module.lexer = Lexer

--#################################################################################################################################################
--#################################################################################################################################################
--#################################################################################################################################################

-- attempts to transform tokens into stringed tokens

local Dash = require('./@CHL>DashSingular')

export type transformed_token = {
	transformation: string;
} & token

export type string_transformer = {
	lexer: lexer;
	nested_transformer: string_transformer?;
} & simple_iterator<transformed_token>

StringTransformer = {}
compose = Dash.compose

function StringTransformer.new(lexer: lexer): string_transformer
	local self: string_transformer = Object.simple.new(StringTransformer)
	self.lexer = lexer
	return self
end

function StringTransformer.can_proceed(self: string_transformer): boolean
	return self.lexer:can_proceed()
end

function StringTransformer.proceed(self: string_transformer)
	if not self:can_proceed() then return end
	
	local nested_transformer = self.nested_transformer
	
	if nested_transformer then
		assert(nested_transformer:can_proceed())
		local result = nested_transformer:proceed()
		
		if not nested_transformer:can_proceed() then
			self.nested_transformer = nil
		end
		
		return result
	end
	
	local token = self.lexer:proceed()
	local token_type = token.token_type
	local value = token.value
	
	if not (token_type == value or token_type == 'delimiter') then
		if typeof(value) == 'string' then
			-- specific case where we decide to keep string as is or proceed
			-- to lua_stringify it
			if not (token_type == 'index' and token.is_sugar_index) then
				value = StringUtils.lua_string.from_raw(value, {
					multiline_type = 'single';
					token = '\''
				} :: StringUtils.lua_string_args)
			end
		elseif typeof(value) == 'table' then
			local metatable = getmetatable(value)
			local to_string = metatable and metatable.__tostring
			
			if to_string then
				value = to_string(value)
			else
				-- TODO: Check recursive case
				local nested_transformer = StringTransformer.new(Lexer.new(value))
				
				self.nested_transformer = nested_transformer
				value = nested_transformer:proceed().transformation
				assert(value, 'nested transformer failed to proceed')
			end
		else
			value = tostring(value)
		end
	end
	
	token.transformation = value
	
	return token
end

StringTransformer.from = {}
StringTransformer.from.table = compose(Lexer.new, StringTransformer.new) :: (any_map) -> string_transformer

module.string_transformer = StringTransformer

Iterator.simple.declare_as(StringTransformer)
Class.make_proper_class(StringTransformer, '@CHL>TableToString>StringTransformer')

--#################################################################################################################################################
--#################################################################################################################################################
--#################################################################################################################################################

-- beautifier
export type beautifier = {
	transformer: string_transformer;
	queue: {string};
	indent_token: string;
	indent: number;
	proceeded: string;
	
	enqueue_string: (self: beautifier, s: string)->();
	enqueue_indents: (self: beautifier, n: number?)->();
	enqueue_line_break: (self: beautifier)->();
	get_latest: (self: beautifier)->string;
	
	evaluate_to_delimiter: (self: beautifier)->();
	close_table: (self: beautifier)->()
} & simple_iterator<string>

Beautifier = {}
disguise = require('./LuaUTypes').disguise

function Beautifier.new(transformer: string_transformer, indent_token: string?): beautifier
	local self: beautifier = Object.simple.new(Beautifier)
	self.queue = {}
	self.indent_token = indent_token or disguise(module).indent_token
	self.indent = 0
	self.transformer = transformer
	return self
end

function Beautifier.get_latest(self: beautifier)
	return self.queue[1] or self.proceeded
end

function Beautifier.close_table(self: beautifier)
	if self:get_latest() ~= '{' then -- case where table is not immediately empty
		self.indent -= 1
		self:enqueue_line_break()
		self:enqueue_indents()
	end

	self:enqueue_string('}')
	
	-- case where closing a table leads to multiple tables closing
	if self.transformer:can_proceed() then
		local current = self.transformer:proceed()
		
		while current and current.token_type ~= 'delimiter' do
			self.indent -= 1
			self:enqueue_line_break()
			self:enqueue_indents()
			self:enqueue_string('}')
			
			if self.transformer:can_proceed() then
				current = self.transformer:proceed()
			else
				current = nil
			end
		end
		
		if current then
			self:enqueue_string(current.transformation)
		end
	end
end

function Beautifier.evaluate_to_delimiter(self: beautifier, s: string)
	assert(self.transformer:can_proceed())
	
	local current = self.transformer:proceed()
	
	if current.token_type == '}' then -- closing table case
		self:close_table()
	else
		-- entry case
		
		-- whitespace
		self:enqueue_line_break()
		self:enqueue_indents()
		
		-- index
		local is_not_sugar = current.token_type == '['
		if is_not_sugar then
			self:enqueue_string('[')
		end
		
		local has_index = is_not_sugar or current.token_type == 'index'
		
		if is_not_sugar then
			assert(self.transformer:can_proceed())
			current = self.transformer:proceed()
		end
		
		if has_index then
			self:enqueue_string(current.transformation)
		end
		
		if is_not_sugar then
			local check = self.transformer:proceed()
			assert(check.transformation == ']', 'incomplete non sugar index')
			self:enqueue_string(']')
		end
		
		if has_index then
			-- possible case where user wants different whitespace around equals
			local check = self.transformer:proceed()
			
			if check.token_type ~= '=' then
				print(self)
				end
			
			assert(check.token_type == '=', 'index assigned but no equals')
			
			self:enqueue_string(' ')
			self:enqueue_string('=')
			self:enqueue_string(' ')
			
			current = self.transformer:proceed()
		end
		
		-- value
		self:enqueue_string(current.transformation)
		
		local is_type_table = typeof(current.value) == 'table'
		
		if is_type_table then -- ig in the case of table construction, { is a delimiter
			self.indent += 1
			return
		end
		
		-- delimiter
		current = self.transformer:proceed()
		
		if current.token_type == 'delimiter' then
			self:enqueue_string(current.transformation)
		elseif current.token_type == '}' then
			self:close_table()
		else
			print(self)
			print(current)
			error('how did we get here?')
		end
	end
end

function Beautifier.enqueue_line_break(self: beautifier, s: string)
	self:enqueue_string('\n')
end

function Beautifier.enqueue_string(self: beautifier, s: string)
	table.insert(self.queue, s)
end

function Beautifier.enqueue_indents(self: beautifier, n: number)
	n = n or self.indent
	for i = 1, n do
		self:enqueue_string(self.indent_token)
	end
end

function Beautifier.can_proceed(self: beautifier): boolean
	return self.transformer:can_proceed() or #self.queue > 0
end

function Beautifier.proceed(self: beautifier)
	if not self:can_proceed() then return end
	
	if #self.queue > 0 then
		local result = tremove(self.queue, 1)
		self.proceeded = result
		return result
	elseif not disguise(self).proceeded then -- beginning of entire table
		assert(self.transformer:can_proceed())
		local token = self.transformer:proceed()
		
		assert(token.token_type == '{')
		
		self.indent = 1
		self:enqueue_string('{')
	else
		-- entry cases
		self:evaluate_to_delimiter()
	end
	
	if #self.queue > 0 then
		return self:proceed()
	else
		error('how did we get here?')
	end
end

Beautifier.indent_token = '    '

Beautifier.from = {}
Beautifier.from.lexer = compose(StringTransformer.new, Beautifier.new) :: (lexer) -> beautifier
Beautifier.from.table = compose(Lexer.new, Beautifier.from.lexer) :: (any_map) -> beautifier

Iterator.simple.declare_as(Beautifier)
Class.make_proper_class(Beautifier, '@CHL>TableToString>Beautifier')

module.beautifier = Beautifier

--#################################################################################################################################################
--#################################################################################################################################################
--#################################################################################################################################################

function module.to_beautified_string(t: any_map): string
	local beautifier = Beautifier.from.table(t)
	local tokens = {}
	
	while beautifier:can_proceed() do
		table.insert(tokens, beautifier:proceed())
	end
	
	return table.concat(tokens)
end

return module
