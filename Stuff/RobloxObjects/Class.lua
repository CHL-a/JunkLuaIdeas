--[[
	more modifications of such:
	 * bug fixes
	 * __super strictly checks methods from self and up within method contexting
	 * __proxy<a> and __method<a>
]]

type __subclass<super> = super & {
	__supers: {super};
	__super: super;
}
export type subclass<A> = __subclass<A>

type __function = (...any) -> ...any

type __super<A> = {
	__object: A & __subclass<A>;
	__class: {[string]:__function};
	__super: __super<A>;

	__get_i: (self:__super<A>) -> nil;
}

type __class = {[string]: __function}

type __method<A> = {
	__proxy: __proxy<A>;
	__func: __function;
	__class: __class?;
}

type __proxy<A> = {
	__object: A;
	__is_super: boolean;
	__super: __proxy<A>;
	__super_cached: __proxy<A>;
	__class: __class;

	__get_class_i: (self: __proxy<A>) -> number;
	__get_super_class: (self:__proxy<A>) -> __class?;
	__get_method: (self:__proxy<A>, name: string) -> __method<A>;
	__clone: (self:__proxy<A>) -> __proxy<A>
}

local Class = {}
local disguise = function<A>(x): A return x end

local Method = {}

local Proxy = {}
Proxy.__index = function<A>(self: __proxy<A>, i: string)
	-- needs super and method handling
	-- self.__super
	if i == '__super' then
		local cached = rawget(self,'__super_cached')
		if cached then
			cached.__is_super = true
			return cached
		end

		local __super_class = self:__get_super_class()
		if not __super_class then return end;

		local __super = disguise(Proxy).new(self.__object, __super_class)
		rawset(self,'__super_cached', __super)

		return __super
	end

	-- self index
	local self_val = rawget(self,i) or Proxy[i]

	if self_val ~= nil then
		return self_val
	end

	-- self.__object methods
	local method = self:__get_method(i)
	if method then
		return method
	end

	-- self.__object regular values
	local val = rawget(disguise(self.__object),i)

	if val ~= nil then return val end
end
Proxy.__newindex = function<A>(self: __proxy<A>, i: string, v:any)
	rawset(disguise(self).__object, i, v)
end
Proxy.new = function<A>(object: A, class)
	local self: __proxy<A> = disguise(setmetatable({
		__object = object;
		__class = class;
		__is_super = false
	}, Proxy))

	return self
end
Proxy.__get_class_i = function<A>(self: __proxy<A>)
	return assert(
		table.find(
			rawget(
				disguise(self).__object, 
				'__supers'
			), 
			self.__class
		)
	)
end
Proxy.__get_super_class = function<A>(self:__proxy<A>)
	local i = self:__get_class_i()

	for j = i - 1, 1, -1 do
		local class = disguise(self.__object).__supers[j]

		if type(class) == 'table' then
			return class
		end
	end

	return nil
end
Proxy.__get_method = function<A>(self:__proxy<A>,name: string)
	local supers = disguise(self.__object).__supers
	local start = self.__is_super and self:__get_class_i() or #supers

	local j
	local m
	for i = start, 1, -1 do
		local v = supers[i]

		if type(v) ~= 'table' then continue end;

		if v[name] then
			j = i
			m = v[name]
			break
		end
	end

	if not m then
		-- error(`Proxy fail: no method: {name}`)
		
		return nil
	end

	local rep = self.__object

	if j ~= #supers then
		repeat
			rep = rep.__super
		until rep and type(rep.__class) == 'table' and rep.__class[name] == m
	end

	assert(rep, 'inaccessable')
	--- print('a',rep)

	return disguise(Method).new(
	rep,
	m,
	rawget(rep,'__class')
	)
end
Proxy.__clone = function<A>(self:__proxy<A>)
	return Proxy.new(self.__object, self.__class)
end

Method.__index = Method
Method.__call = function<A>(self: __method<A>,_ ,...)
	if self.__proxy.__is_super ~= nil then
		self.__proxy.__is_super = false
	end
	return self.__func(self.__proxy, ...)
end

Method.new = function<A>(object: A, func: __function, class:__class?)
	local self: __method<A> = disguise(setmetatable({}, Method))
	self.__proxy = disguise(object);
	self.__func = func
	self.__class = class

	return self
end

function getLatestFunction<A>(self: __subclass<A>, i: string)
	if i == '__supers' and not rawget(self,'__supers') then return end

	local supers = self.__supers

	if i == '__super' then
		for i = #supers - 1, 1, -1 do
			local class = supers[i]

			if type(class) == 'table'then
				local cached = Proxy.new(self, class)
				disguise(self).__super_cached = cached
				cached.__is_super = true
				return cached
			end
		end

		return;
	end


	local first = supers[#supers]

	if type(first) == 'table' and first[i] then
		return first[i]
	end

	local current = self
	local method

	repeat
		current = current.__super

		if not current then return end;

		method = current.__class[i]
	until method

	return Method.new(current, method, current.__class)
end

function inherit<A>(t: A, methods, is_debugging): __subclass<A>
	local result: __subclass<A> = disguise(t)
	local supers = result.__supers or {}
	result.__supers = supers

	-- metatable evaluation
	local old_metatable = getmetatable(disguise(result))

	if old_metatable and
		old_metatable.__index and
		old_metatable.__index ~= getLatestFunction then
		table.insert(supers, old_metatable.__index)
		old_metatable = table.clone(old_metatable)
		old_metatable.__index = getLatestFunction
	end

	if methods then
		table.insert(supers, methods)
	end

	setmetatable(disguise(result), old_metatable) -- do something here later?

	local _ = result.__super

	return result
end

Class.inherit = inherit

function isClass(obj, class)
	local supers = obj.__supers

	if not supers then
		return getmetatable(obj) == class
	else
		return supers[#supers] == class
	end
end

Class.isClass = isClass

function hasClass(obj, class)
	return isClass(obj, class) or 
		obj.__supers and not not table.find(obj.__supers, class)
end

Class.hasClass = hasClass

Class.abstractMethod = function()error('Attempting to use abstract method')end

return Class
