-- types
local Objects = game.ReplicatedStorage.Objects

local Class = require(Objects.Class)
local Iterator = require(Objects.Iterator)

type __object<A> = {
	referral: {[any]: any};
	stack: {any};
	dupe_stack: {any};
	didIterated: boolean;
	
	getDupeStack: (self:__object<A>) -> {any};
	getValue: (self:__object<A>) -> any;
} & Class.subclass<Iterator.object<{A?}>>
export type object<A> = __object<A>

-- implementation
local disguise = require(Objects.LuaUTypes).disguise

local module = {}
module.__index = module

-- pub
module.new = function<A>(ref)
	local self: __object<A> = disguise(Class.inherit(Iterator.new(), module))
	self.referral = ref
	self.stack = {}
	self.dupe_stack = {}
	self.didIterated = false
	
	local i = next(ref)
	
	if i ~= nil then
		table.insert(self.stack,i)
	end
	
	return self
end

module.getDupeStack = function<A>(self:__object<A>)
	local dupe = self.dupe_stack
	
	table.clear(dupe)
	
	for i, v in next, self.stack do
		dupe[i] = v
	end
	
	return dupe
end

module.getValue = function<A>(self: __object<A>)
	local current = self.referral
	
	for _, v in next, self.stack do
		current = current[v]
	end
	
	return current
end

module.canProceed = function<A>(self:__object<A>)
	return #self.stack > 0
end

module.proceed = function<A>(self:__object<A>)
	local stack = self.stack
	
	-- first
	if not self.didIterated then
		self.didIterated = true
		return self:getDupeStack()
	end
	
	-- other
	local referral = self.referral
	
	local didPop = false
	
	while #stack > 0 do
		local current = self:getValue()

		if type(current) == 'table' and not didPop then
			local i = next(current)
			
			if i ~= nil then
				table.insert(stack, i)
				break;
			end
		end
		
		didPop = false
		
		local i = table.remove(stack)
		local parent = self:getValue()
		
		local new_i = next(parent, i)
		
		if new_i ~= nil then
			table.insert(stack, new_i)
			break;
		end
		
		didPop = true
	end
	
	return self:getDupeStack()
end

return module
