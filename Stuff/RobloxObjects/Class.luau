--[[
	more modifications of such:
	 * bug fixes
	 * __super strictly checks methods from self and up within method contexting
	 * __proxy<a> and __method<a>
]]
--// TYPES
local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>
type dictionary<A> = Map.dictionary<A>

export type subclass<super> = super & {
	__supers: {super};
	__super: super;
}
type __function = (...any) -> ...any

type __super<A> = {
	__object: A & subclass<A>;
	__class: dictionary<__function>;
	__super: __super<A>;

	__get_i: (self:__super<A>) -> ();
}

type __class = dictionary<__function>

type __method<A> = {
	__proxy: __proxy<A>;
	__func: __function;
	__class: __class?;
	__name: string?;
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
	__clone: (self:__proxy<A>) -> __proxy<A>;
	__get_value: <V>(self: __proxy<A>, i: string) -> V;
}

--// MAIN
local Class = {}
local LuaUTypes = require('./LuaUTypes')

disguise = LuaUTypes.disguise
find = table.find
clone = table.clone
insert = table.insert

local Method = {}

local Proxy = {}

function Proxy.__index<A>(self: __proxy<A>, i: string)
	-- needs super and method handling
	-- self.__super
	if i == '__super' then
		local __super_class = self:__get_super_class()
		if not __super_class then return end;

		local __super: __proxy<A> = disguise(Proxy).new(self.__object, __super_class)
		rawset(self,'__super', __super)
		__super.__is_super = true

		return __super
	end

	-- self index
	local self_val = rawget(self,i) or Proxy[i]

	if self_val ~= nil then return self_val end

	-- self.__object methods
	local method = self:__get_method(i)
	if method then return method end

	-- self.__object regular values
	local val = self:__get_value(i)

	if val ~= nil then return val end
end

function Proxy.__newindex<A>(self: __proxy<A>, i: string, v:any)
	rawset(disguise(self).__object, i, v)
end

function Proxy.new<A>(object: A, class)
	local self: __proxy<A> = disguise(setmetatable({
		__object = object;
		__class = class;
		__is_super = false;
		__is_proxy = true;
	}, Proxy))

	return self
end

function Proxy.__get_class_i<A>(self: __proxy<A>)
	return assert(
		find(
			rawget(disguise(self).__object, '__supers'), 
			self.__class
		)
	)
end

function Proxy.__get_super_class<A>(self:__proxy<A>)
	local i = self:__get_class_i()

	for j = i - 1, 1, -1 do
		local class = disguise(self.__object).__supers[j]

		if type(class) == 'table' then
			return class
		end
	end
end

function Proxy.__get_method<A>(self:__proxy<A>,name: string)
	local supers = disguise(self.__object).__supers
	local start = self.__is_super and self:__get_class_i() or #supers

	-- get method
	local j
	local m
	for i = start, 1, -1 do
		local superclass = supers[i]
		if type(superclass) ~= 'table' then continue end;
		
		local fn = superclass[name]
		
		if type(fn) == 'function' then
			j = superclass
			m = fn
			break
		end
	end

	-- check method existance
	if not m then return end

	-- return psuedo method
	local clone = self:__clone()
	clone.__class = j

	return disguise(Method).new(clone,m,j,name)
end

function Proxy.__clone<A>(self:__proxy<A>)
	return Proxy.new(self.__object, self.__class)
end

function Proxy.__get_value<A, B>(self: __proxy<A>, name: string): B
	local v = rawget(disguise(self.__object),name)
	if v ~= nil then return v;end
	
	local supers = disguise(self.__object).__supers
	local start = self.__is_super and self:__get_class_i() or #supers
	
	-- get method
	
	for i = start, 1, -1 do
		local superclass = supers[i]
		if type(superclass) ~= 'table' then continue end;

		local v = superclass[name]
		if type(v) == 'function' then continue end
		
		return v
	end
	return disguise()
end

Method.__index = Method

function Method.__call<A>(self: __method<A>,_ ,...)
	--[[
	local a, b = ...
	if type(a) == 'number' and typeof(b) == 'Vector3' then
		print('c',self)
	end
	--]]
	
	return self.__func(self.__proxy, ...)
end

function Method.new<A>(object: A, func: __function, class:__class?,name: string?)
	local self: __method<A> = disguise(setmetatable({}, Method))
	self.__proxy = disguise(object);
	self.__func = func
	self.__class = class
	self.__name = name

	return self
end

--##################################################################################
--##################################################################################
--##################################################################################

function getLatestFunction<A>(self: subclass<A>, i: string)
	if i == '__supers' and not rawget(self,'__supers') then return end

	local supers = self.__supers
	local first = supers[#supers]

	-- first method always returned raw
	local first_check = first.__index
	
	if type(first_check) == 'table' and first_check[i] then
		return first_check[i]
	elseif typeof(first_check) == 'function' then
		local got = first_check(self, i)
		if got then return got end
	end
	
	-- upper class methods returned psuedo
	for j = #supers - 1, 1, -1 do
		local class = supers[j]
		local __indexF = class.__index
		
		if not (typeof(__indexF) == 'table' ) then 
			if type(__indexF) == 'function' then
				if __indexF == getLatestFunction then
					print(self,supers)
					error('Attempted to recurse: using getLatestFunction within .__supers')
				end
				
				return __indexF(self, i)
			end
			continue;
		end

		local m = class[i]
		if not m then continue end;

		return Method.new(Proxy.new(self, class), m, class, i)
	end
end

function other(s: string)
	return function<A>(self: subclass<A>, ...)
		local fn = disguise(self)[s]
		
		if not fn then
			error(`Attempting to use operation on uninoperable object: {s}`)
		end
		
		return fn(self, ...)
	end
end

mainMeta = {__index = getLatestFunction}
specialMeta = ('__mode,__metatable,__newindex,__tostring,__index'):split(',')
overwritableMeta = ('__newindex,__tostring'):split(',')

for _, v in LuaUTypes.metamethods do
	if find(specialMeta, v) then continue end
	
	mainMeta[v] = other(v)
end

function inherit<A, B>(t: A, methods, is_debugging): B-- __subclass<A>
	if disguise(t).__is_proxy == true then
		t = disguise(t).__object
	end
	
	local _t = disguise(t)
	local result: subclass<A> = disguise(_t)
	
	local supers = rawget(result,'__supers') or {}; 
	rawset(result,"__supers", supers)
	
	-- metatable evaluation
	local metatable = getmetatable(disguise(result))
	
	if not metatable then setmetatable(_t, mainMeta)
	elseif metatable.__index ~= getLatestFunction then
		if metatable then
			insert(supers, metatable.__index)
		end
		
		local new_metatable = mainMeta
		
		if metatable then
			local didClone = new_metatable.__is_clone
			
			for _, v in next, overwritableMeta do
				if not metatable[v] then continue end
				
				if not didClone then
					new_metatable = clone(new_metatable)
					didClone = true
				end
				
				new_metatable[v] = other(v)
			end
			
			new_metatable.__is_clone = didClone
		end
		
		setmetatable(_t, new_metatable)
	end
	
	if methods then
		insert(supers, methods)
		
		local meta = getmetatable(_t)
		local did_clone = meta.__is_clone
		
		for _, v in next, overwritableMeta do
			if not (methods[v] and not meta[v]) then continue; end
			
			if not did_clone then
				meta = clone(meta)
				did_clone = true
			end

			meta[v] = other(v)		
		end
		
		meta.__is_clone = did_clone
		setmetatable(_t, meta)
	end
	
	--[[] ]
	if new_metat then
		setmetatable(disguise(result), new_metat) -- do something here later?
	end
	--]]
	
	-- set up self.__super
	for i = #supers - 1, 1, -1 do
		local class = supers[i]

		if type(class) == 'table'then
			local super = Proxy.new(result, class)
			super.__is_super = true
			rawset(result, '__super', super)
			break;
		end
	end

	return _t
end

function isClass(obj, class)
	local supers = obj.__supers

	if not supers then
		return getmetatable(obj) == class
	end

	return supers[#supers] == class
end

function isProperClass(CLASS): (boolean, number?, string?)
	if not CLASS.__index then return false, 1, 'CLASS.__index is falsy.'
	elseif type(CLASS.className) ~= 'string' then 
		return false, 2, 'CLASS.className is not a string.'
	end
	
	return true
end

function hasClass(obj, class)
	return isClass(obj, class) or 
		obj.__supers and not not find(obj.__supers, class)
end

function getErrorFunc(s: string) return function() error(s) end end

function makeProperClass<A>(CLASS: A, name: string)
	local c = disguise(CLASS)
	if not c.__index then
		c.__index = c
	end
	
	c.className = assert(name)
end

--########################################################################################
--########################################################################################
--########################################################################################

--Class.getLatestFunction = getLatestFunction
Class.isProperClass = isProperClass
Class.inherit = inherit
Class.isClass = isClass
Class.hasClass = hasClass
Class.abstractMethod = getErrorFunc'Attempting to use abstract method.'
Class.unimplemented = getErrorFunc'Attempting to use an unimplemented method.'
Class.makeProperClass = makeProperClass

return Class
