type __object<A> = {
	content: {A};
	
	isEmpty: (self:__object<A>) -> boolean;
	enqueue: (self: __object<A>, ...A) -> nil;
	dequeue: (self:__object<A>) -> A;
	getFront: (self:__object<A>) -> A;
	clear: (self:__object<A>) -> nil
}

export type object<A> = __object<A>

local module = {}
module.__index = module

local function disguise<A>(x) : A return x end

module.new = function<A>()
	local self: __object<A> = disguise(setmetatable({}, module))
	self.content = {}
	
	return self;
end

module.isEmpty = function<A>(self: __object<A>)return #self.content == 0 end

module.enqueue = function<A>(self:__object<A>, ...: A)
	for i = 1, select('#', ...) do
		local e = select(i, ...)
		table.insert(self.content, e)
	end
end

module.getFront = function<A>(self: __object<A>)
	assert(not self:isEmpty(), 'attempting to peek at an empty stack')
	return self.content[1]
end

module.dequeue = function<A>(self: __object<A>)
	assert(not self:isEmpty(), 'attempting to pop an empty stack')
	return table.remove(self.content,1)
end

module.clear = function<A>(self: __object<A>)table.clear(self.content)end

return module
