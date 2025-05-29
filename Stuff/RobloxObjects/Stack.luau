export type object<A> = {
	content: {A};
	
	isEmpty: (self:object<A>) -> boolean;
	push: (self: object<A>, ...A) -> ();
	pop: (self:object<A>) -> A;
	peek: (self:object<A>) -> A;
	clear: (self:object<A>) -> ()
}

--#########################################################################################
--#########################################################################################
--#########################################################################################

local module = {}
local LuaUTypes = require('./LuaUTypes')

disguise = LuaUTypes.disguise

function module.new<A>(): object<A>
	local self: object<A> = disguise(setmetatable({}, module))
	self.content = {}
	
	return self;
end

function module.isEmpty<A>(self: object<A>)return #self.content == 0 end

function module.push<A>(self:object<A>, ...: A)
	for i = 1, select('#', ...) do
		local e = select(i, ...)
		table.insert(self.content, e)
	end
end

function module.peek<A>(self: object<A>)
	assert(not self:isEmpty(), 'attempting to peek at an empty stack')
	return self.content[#self.content]
end

function module.pop<A>(self: object<A>)
	assert(not self:isEmpty(), 'attempting to pop an empty stack')
	return table.remove(self.content)
end

function module.clear<A>(self: object<A>)table.clear(self.content)end

module.__index = module

--#########################################################################################
--#########################################################################################
--#########################################################################################

return module
