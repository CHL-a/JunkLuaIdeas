local module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Iterator = require('./@CHL>Iterator')
local Set = require('./@CHL>Set')
local Object = require('./Object')
local Class = require('./Class')
local Dash = require('./@CHL>DashSingular')
local StringUtils = require('./@CHL>StringUtils')

type iterator_simple<A, B...> = Iterator.simple<A, B...>
type char_iterator = StringUtils.char_iterator
type set<A> = Set.simple<A>

-- types of encoding types when encountering a character
type escape_check_type = 
	'all' | 
	'xml_necessary' |  -- includes &<>'"
	'amp_necessary' | -- only incudes & since it's really the only actual escape character
	'custom'

-- because html escapes involve singular characters, then this iterator is a byte iterator
-- iterates per character, returns a byte, then if its a valid escape (boolean)
export type escape_lexer = {
	-- possible to replace this with utf8 iterator, later
	referral: char_iterator;
	escape_type: escape_check_type;
	escape_check_set: set<number> | set<string>;
	
	set_escape_type: (self: escape_lexer, escape_check_type | set<number> | set<string>)->();
} & iterator_simple<number, boolean>

disguise = require('./LuaUTypes').disguise
compose = Dash.compose
EscapeLexer = {}
EscapeLexer.from = {}

EscapeLexer.escape_type_character_sets = {
	xml_necessary = Set.simple.from.chars'&<>\'"';
	amp_necessary = Set.simple.from.chars'&';
}

function EscapeLexer.new(char_iterator: char_iterator): escape_lexer
	local self: escape_lexer = Object.simple.new(EscapeLexer)
	self.referral = char_iterator
	self:set_escape_type('xml_necessary')
	
	return self
end

function EscapeLexer.set_escape_type(self: escape_lexer, arg: escape_check_type | set<number> | set<string>)
	local escape_type: escape_check_type = 'custom'
	local set;
	
	if arg == 'custom' then
		error('arg "custom" is read-only' )
	elseif type(arg) == 'table' then
		set = arg
	elseif EscapeLexer.escape_type_character_sets[arg] then
		set = EscapeLexer.escape_type_character_sets[arg]
		escape_type = arg
	elseif arg == 'all' then
		escape_type = 'all'
	end
	
	self.escape_type = escape_type
	self.escape_check_set = set
end

function EscapeLexer.can_proceed(self: escape_lexer)
	return self.referral:can_proceed()
end

function EscapeLexer.proceed(self: escape_lexer)
	if not self:can_proceed() then return;end
	
	local char = self.referral:proceed()
	local byte = char:byte()
	local is_escape = false
		
	if self.escape_type == 'all' or self.escape_check_set[char] or self.escape_check_set[byte] then
		is_escape = true
	end
	
	return byte, is_escape
end

Class.makeProperClass(EscapeLexer, '@CHL>HTMLEscape>Escape>Lexer')

EscapeLexer.from.string = compose(StringUtils.iterator.char.from.string, EscapeLexer.new) :: (string)->(escape_lexer)

module.escape = {}
module.escape.lexer = EscapeLexer

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>

export type escape_transform_type = 'number' 
	-- | 'hex'  -- possible consideration of this being added in the future
	-- | 'custom'
	| 'named'

-- returns an escaped string
export type escape_transformer = {
	lexer: escape_lexer;
	transform_type: escape_transform_type;
} & iterator_simple<string>

EscapeTransform = {}
to_char = string.char

function EscapeTransform.simple(byte: number, transformation: (map<number, string> | map<string, string>)? )
	local char = to_char(byte)
	local transformed = (transformation and (transformation[char] or transformation[byte])) or `#{byte}` 
	
	return `&{transformed};`
end

function EscapeTransform.new(lexer: escape_lexer): escape_transformer
	local self: escape_transformer = Object.simple.new(EscapeTransform)
	self.lexer = lexer
	self.transform_type = 'named'
	return self
end

function EscapeTransform.can_proceed(self: escape_transformer): boolean
	return self.lexer:can_proceed()
end

function EscapeTransform.proceed(self: escape_transformer): string
	if not self:can_proceed() then return;end
	
	local byte, is_escape = self.lexer:proceed()
	
	if not is_escape then
		return to_char(byte)
	end
	
	local transformation
	
	if self.transform_type == 'named' then
		transformation = EscapeTransform.transformations[self.lexer.escape_type] or EscapeTransform.transformations.xml_necessary
	end
	
	local transformed = EscapeTransform.simple(byte, transformation)
	
	return transformed
end

EscapeTransform.transformations = {
	amp_necessary = {['&'] = 'amp'};
	xml_necessary = {['&'] = 'amp', ['<'] = 'lt', ['>'] = 'gt', ['"'] = 'quot', ["'"] = 'apos'};
}

EscapeTransform.from = {}
EscapeTransform.from.string = compose(EscapeLexer.from.string, EscapeTransform.new) :: (string)->(escape_transformer)

module.escape.transform = EscapeTransform

Class.makeProperClass(EscapeTransform, '@CHL>HTMLEscape>Escape>Transform')

--#####################################################################################
--#####################################################################################
--#####################################################################################

function module.escape.on_string(s: string)
	local transform = EscapeTransform.from.string(s)
	local consumer = StringUtils.consumer.char.new()
	
	while transform:can_proceed() do
		consumer:consume(transform:proceed())
	end
	
	return consumer.referral
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

type byte_iterator = StringUtils.byte_iterator

-- iterates in string, iterates per token, including characters or escape sequences
export type unescape_lexer = {
	referral: byte_iterator;
} & iterator_simple<string>

UnescapeLexer = {}

function UnescapeLexer.new(byte_it: byte_iterator): unescape_lexer
	local self: unescape_lexer = Object.simple.new(UnescapeLexer)
	self.referral = byte_it
	
	return self
end

function UnescapeLexer.can_proceed(self: unescape_lexer)
	return self.referral:can_proceed()
end

function UnescapeLexer.proceed(self: unescape_lexer)
	local byte = self.referral:proceed()
	local char = to_char(byte)
	local result = char
	
	if char == UnescapeLexer.escape_delimiter_start then
		local characters = {char}
		local next_char;
		
		repeat
			if not self.referral:can_proceed() then
				break;
			end
			
			next_char = to_char(self.referral:proceed())
			table.insert(characters, next_char)
		until next_char == UnescapeLexer.escape_delimiter_end
		
		if next_char ~= UnescapeLexer.escape_delimiter_end then
			print(characters)
			error('unable to proceed: bad sequence')
		end
		
		result = table.concat(characters)
	end
	
	return result
end

UnescapeLexer.escape_delimiter_start = '&'
UnescapeLexer.escape_delimiter_end = ';'
UnescapeLexer.from = {}
UnescapeLexer.from.string = compose(StringUtils.iterator.byte.new, UnescapeLexer.new) :: (string)->unescape_lexer

Class.makeProperClass(UnescapeLexer, '@CHL>HTMLEscape>Unescape>Lexer')

module.unescape = {}
module.unescape.lexer = UnescapeLexer

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type unescape_transformer = {
	lexer: unescape_lexer;
} & iterator_simple<string>

UnescapeTransform = {}

UnescapeTransform.named_transformations = {
	lt = '<';
	gt = '>';
	apos = "'"; --'
	quot = '"'; --"
	amp = '&'; --&
}

UnescapeTransform.decimal_transformation = '#'
UnescapeTransform.hex_transformation = 'x'

function UnescapeTransform.simple(s: string)
	local result = s;
	
	if s:sub(1, 1) == UnescapeLexer.escape_delimiter_start and s:sub(-1) == UnescapeLexer.escape_delimiter_end then
		local inside = s:sub(2, -2)
		local first = inside:sub(1,1):lower()
		
		if first == UnescapeTransform.decimal_transformation or first == UnescapeTransform.hex_transformation then
			local written_byte = inside:sub(2)
			local byte = tonumber(`0{written_byte}`)
			result = to_char(byte)
		elseif UnescapeTransform.named_transformations[inside] then
			result = UnescapeTransform.named_transformations[inside]
		else
			error(`unknown transformation: {inside}`)
		end
	end
	
	return result
end

function UnescapeTransform.new(u_l: unescape_lexer): unescape_transformer
	local self: unescape_transformer = Object.simple.new(UnescapeTransform)
	self.lexer = u_l
	return self
end

function UnescapeTransform.can_proceed(self: unescape_transformer)
	return self.lexer:can_proceed()
end

function UnescapeTransform.proceed(self: unescape_transformer)
	if not self:can_proceed() then return end
	local str = self.lexer:proceed()
	
	str = UnescapeTransform.simple(str)
	
	return str
end

UnescapeTransform.from = {}
UnescapeTransform.from.string = compose(UnescapeLexer.from.string, UnescapeTransform.new) :: (string)->unescape_transformer

module.unescape.transform = UnescapeTransform

Class.makeProperClass(UnescapeTransform, '@CHL>HTMLEscape>Unescape>Transform')

--#####################################################################################
--#####################################################################################
--#####################################################################################

function module.unescape.on_string(s: string)
	local transform = UnescapeTransform.from.string(s)
	local consumer = StringUtils.consumer.char.new()

	while transform:can_proceed() do
		consumer:consume(transform:proceed())
	end

	return consumer.referral
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
