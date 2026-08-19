local Iterator = require('./@CHL>Iterator')
local Class = require('./Class')
local Object = require('./Object')

export type symbols = {
	separator: string;
	current: string;
	parent: string;
}

-- parses the path as is, regardless if the path is absolute or relative
export type parser = {
	path: string;
	symbols: symbols;
	i: number;
	is_absolute: boolean;
	ahead: string;
	
	fetch: (self: parser) -> string?;
} & Iterator.simple<string>

local module = {}

parser = {}

function parser.new(path: string, symbols: symbols?): parser
	local self: parser = Object.simple.new(parser)
	local symbols_2 = symbols or parser.symbols
	local separator = symbols_2.separator
	
	self.path = path
	self.is_absolute = path:sub(1,#separator) == separator
	self.i = self.is_absolute and 2 or 1
	self.symbols = symbols
	self.ahead = self:fetch()
	
	return self
end

function parser.fetch(self: parser): string?
	local path = self.path
	local i = self.i
	local at_end = i > #path
	
	if at_end then
		return
	end
	
	local separator_start, separator_end = path:find(parser.symbols.separator, i, true)
	local ahead = separator_start and path:sub(i, separator_start - 1) or path:sub(i)
	local new_i = separator_end and separator_end + 1 or #path + 1
	
	self.i = new_i
	
	return ahead
end

function parser.can_proceed(self: parser): boolean
	return not not self.ahead
end

function parser.proceed(self: parser)
	if not self:can_proceed() then return end
	
	local result = self.ahead
	
	self.ahead = self:fetch()
	
	return result
end

parser.symbols = {
	separator = '/';
	current = '.';
	parent = '..'
}

Class.make_proper_class(parser, '@CHL>Hierarchy>Parser')

module.parser = parser

--######################################################################################################################################################################################################
--######################################################################################################################################################################################################
--######################################################################################################################################################################################################

export type instance_path_parser = {
	parser: parser;
	current: Instance;
	root: Instance;
	
	all: (self: instance_path_parser)->Instance?
} & Iterator.simple<Instance>

export type hierarchal_query_struct = {
	query: string;
	current_working_instance: Instance;
	root_instance: Instance?
}

local Dash = require('./@roblox>Dash')

instance_path_parser = {}

function instance_path_parser.new(h_query: hierarchal_query_struct): instance_path_parser
	local self: instance_path_parser = Object.simple.new(instance_path_parser)
	local parser = parser.new(h_query.query)
	local root = h_query.root_instance or game
	
	self.parser = parser
	self.root = root
	self.current = parser.is_absolute and root or h_query.current_working_instance or root
	
	print(self)
	
	return self
end

function instance_path_parser.can_proceed(self: instance_path_parser)
	return self.parser:can_proceed()
end

function instance_path_parser.proceed(self: instance_path_parser)
	if not self:can_proceed() then return end
	
	local element = self.parser:proceed()
	local current = self.current
	local symbols = self.parser.symbols
	
	if element == symbols.current then
		current = current -- explicit current
	elseif element == symbols.parent then
		if current ~= self.root then
			current = current.Parent
		end
	else
		current = current:FindFirstChild(element)
	end
	
	self.current = current
	
	return current
end

function instance_path_parser.all(self: instance_path_parser)
	local result = self.current
	
	while self:can_proceed() do
		result = self:proceed()
	end
	
	return result
end

Dash.promise:await()

instance_path_parser.invoke_query = Dash.compose(instance_path_parser.new, instance_path_parser.all) :: (hierarchal_query_struct)->Instance?

Class.make_proper_class(instance_path_parser, '@CHL>Hierarchy')

module.instance_path_parser = instance_path_parser

return module
