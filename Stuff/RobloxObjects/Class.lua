--[[
	more modifications of such:
	 * bug fixes
	 * __super strictly checks methods from self and up within method contexting
	 * __proxy<a> and __method<a>
]]
--// TYPES
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
	__clone: (self:__proxy<A>) -> __proxy<A>
}

--// MAIN
local Class = {}
local Objects = script.Parent
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise
find = table.find
clone = table.clone

local Method = {}

local Proxy = {}
Proxy.__index = function<A>(self: __proxy<A>, i: string)
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
		find(
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
end
Proxy.__get_method = function<A>(self:__proxy<A>,name: string)
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
Proxy.__clone = function<A>(self:__proxy<A>)
	return Proxy.new(self.__object, self.__class)
end

Method.__index = Method
Method.__call = function<A>(self: __method<A>,_ ,...)
	--[[
	local a, b = ...
	if type(a) == 'number' and typeof(b) == 'Vector3' then
		print('c',self)
	end
	--]]
	
	return self.__func(self.__proxy, ...)
end

Method.new = function<A>(object: A, func: __function, class:__class?,name: string?)
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

function getLatestFunction<A>(self: __subclass<A>, i: string)
	if i == '__supers' and not rawget(self,'__supers') then return end

	local supers = self.__supers
	local first = supers[#supers]

	-- first method always returned raw
	if type(first) == 'table' and first[i] then return first[i]end

	-- upper class methods returned psuedo
	for j = #supers - 1, 1, -1 do
		local class = supers[j]
		if not (typeof(class) == 'table' ) then 
			if type(class) == 'function' then
				return class(self, i)
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

for _, v in next,LuaUTypes.metamethods do
	if find(specialMeta, v) then continue end
	
	mainMeta[v] = other(v)
end

function inherit<A, B>(t: A, methods, is_debugging): B-- __subclass<A>
	local _t = disguise(t)
	local result: __subclass<A> = disguise(_t)
	
	local supers = rawget(result,'__supers') or {}
	rawset(result,"__supers", supers)

	-- metatable evaluation
	local metat = getmetatable(disguise(result))
	
	local new_metat
	
	if not metat or metat.__index ~= getLatestFunction then
		new_metat = mainMeta
		
		if metat then
			local didClone = false
			
			for _, v in next, overwritableMeta do
				if not metat[v] then continue end
				
				if not didClone then
					new_metat = clone(new_metat)
					didClone = true
				end
				
				new_metat[v] = other(v)
			end
		end
	end
	
	table.insert(supers, metat.__index)
	
	--[[  ] ]
	if metat ~= mainMeta then
		if metat and metat.__index then
			table.insert(supers, metat.__index)
		end
		
		setmetatable(_t, mainMeta)
	end
	--]]
	
	--[[] ]
	if not metat then metat = {}
	else metat = table.clone(metat)
	end
	
	if not metat.__index or
		-- establish __index
		metat.__index ~= getLatestFunction then
		if metat.__index then
			table.insert(supers, metat.__index)
		end
		metat.__index = getLatestFunction
		
		-- establish others
		for _, v in next, LuaUTypes.metamethods do
			for i = #supers, 1, -1 do
				if typeof(supers[i][v]) ~= 'function'then continue; end
				
				metat[v] = extraneousMetamethod(v)
				break
			end
		end
	end
	--]]
	
	if methods then
		table.insert(supers, methods)
	end

	setmetatable(disguise(result), new_metat) -- do something here later?

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

	return disguise(result)
end

function isClass(obj, class)
	local supers = obj.__supers

	if not supers then
		return getmetatable(obj) == class
	end

	return supers[#supers] == class
end

function hasClass(obj, class)
	return isClass(obj, class) or 
		obj.__supers and not not find(obj.__supers, class)
end

function getErrorFunc(s: string) return function() error(s) end end

--########################################################################################
--########################################################################################
--########################################################################################

Class.inherit = inherit
Class.isClass = isClass
Class.hasClass = hasClass
Class.abstractMethod = getErrorFunc'Attempting to use abstract method.'
Class.unimplemented = getErrorFunc'Attempting to use an unimplemented method.'

return Class
