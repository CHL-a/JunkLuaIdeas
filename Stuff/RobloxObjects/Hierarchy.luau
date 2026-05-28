local Iterator = require('./@CHL>Iterator')

export type object = {
	list: {string};
	i: number;
	current: Instance;
	root: Instance;
	
	all: (self: object)->Instance?
} & Iterator.simple<Instance>

export type hierarchal_query_struct = {
	query: string;
	current_working_instance: Instance;
	root_instance: Instance?
}

local Class = require('./Class')
local Object = require('./Object')
local Dash = require('./@CHL>DashSingular')

local module = {}

function module.new(h_query: hierarchal_query_struct): object
	local self: object = Object.simple.new(module)
	local root = h_query.root_instance or game
	
	self.list = h_query.query:split(module.symbols.separator)
	self.i = 1
	self.root = root
	
	if self.list[1] == '' then
		self.current = root
		self.i = 2
	else
		self.current = assert(h_query.current_working_instance)
	end
	
	return self
end

function module.can_proceed(self: object)
	return self.list[self.i] and self.current
end

function module.proceed(self: object)
	if not self:can_proceed() then return end
	
	local element = self.list[self.i]
	local current = self.current
	
	if element == module.symbols.current then
		current = current -- explicit current
	elseif element == module.symbols.parent then
		if current ~= self.root then
			current = current.Parent
		end
	else
		current = current:FindFirstChild(element)
	end
	
	self.i += 1
	self.current = current
	
	return current
end

function module.all(self: object)
	local result;
	
	while self:can_proceed() do
		result = self:proceed()
	end
	
	return result
end

module.invoke_query = Dash.compose(module.new, module.all) :: (hierarchal_query_struct)->Instance?

module.symbols = {
	separator = '/';
	current = '.';
	parent = '..'
}

Class.make_proper_class(module, '@CHL>Hierarchy')

return module
