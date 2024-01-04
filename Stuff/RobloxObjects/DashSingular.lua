--[[
	DashSingular is a warningless version of Dash.
	https://devforum.roblox.com/t/luau-libraries-available-for-use/2692468
	
	! IS UNTESTED
]]
--// TYPES

-- class
type __class<
	ClassName,
	Object,
	ConstructorArgs...
	> = {
	name: ClassName;

	-- creates object, uses constructor upfront
	new: (ConstructorArgs...) -> Object;

	-- init function for class, functionally the same for argument constructor but
	-- finishes set up upon metatable set up
	_init: (self:Object, ConstructorArgs...) -> nil;

	-- checks of value a contains strictly this class by checking its class and all 
	-- classes below.
	isInstance: (a: any) -> boolean;

	-- creates a subclass from class, because of now type checking works, extend is
	-- deparameterized. consider using a type in tangent for type checking.
	extend: (name: string, (...any) -> any) -> any;

	tostring: (self:Object) -> string;
	equals: (self:Object, other: any) -> boolean;

	-- all metamethods.
	__lt: (self:Object, other: Object) -> boolean;
	__le: (self:Object, other: Object) -> boolean;
	__add: (self:Object, other: Object) -> boolean;
	__sub: (self:Object, other: Object) -> boolean;
	__mul: (self:Object, other: Object) -> boolean;
	__div: (self:Object, other: Object) -> boolean;
	__mod: (self:Object, other: Object) -> boolean;
}

export type class<ClassName,Object,ConstructorArgs...> = 
	__class<ClassName,Object,ConstructorArgs...>

export type classReturn = <name, object, args...>(name: string, args...) ->
__class<name, object, args...>

type __object = {
	name: string;
	tostring: (self:__object) -> string;
	equals: (self:__object, other: any) -> boolean;
}
export type object = __object

-- Error
type __Error = {
	name: string;
	message: string;
	tags: Map<string, any>?;
	stack: string;

	joinTags: (self:__Error, Table?) -> __Error;
	throw:(self:__Error, Table?) -> nil;
} & __object
export type Error = __Error

type __ErrorClass = __class<'Error', __Error, (string, string, Table?)>
export type ErrorClass = __ErrorClass

-- Symbol
export type SymbolClass = __class<"Symbol", __object, string>

-- cycles
export type Cycles = {
	-- A set of tables which were visited recursively
	visited: Set<Table>,
	-- A map from table to unique index in visit order
	refs: Map<Table, number>,
	-- The number to use for the next unique table visited
	nextRef: number,
	-- An array of keys which should not be visited
	omit: Array<any>,
}

-- pretty
export type PrettyOptions = {
	-- The maximum depth of ancestors of a table to display (default = 2)
	depth: number?,
	-- An array of keys which should not be visited
	omit: Array<any>?,
	-- Whether to use multiple lines (default = false)
	multiline: boolean?,
	-- Whether to show the length of any array in front of its content
	arrayLength: boolean?,
	-- The maximum length of a line (default = 80)
	maxLineLength: number?,
	-- Whether to drop the quotation marks around strings. By default, this is true for table keys
	noQuotes: boolean?,
	-- The indent string to use (default = "\t")
	indent: string?,
	-- A set of tables which have already been visited and should be referred to by reference
	visited: Set<Table>?,
	-- A cycles object returned from `cycles` to aid reference display
	cycles: Cycles?,
}

-- handlers
type __itHandler<V, I, v> = (V, I) -> v;

-- main module
type __module = {
	class: classReturn;
	Error: __ErrorClass;
	Symbol: SymbolClass;
	None: __object;

	append: <A>(Array<A>, ...A) -> Array<A>;
	assertEqual: (left: any, right: any, msg: string?) -> nil;
	assign: (t: Table, ...Table) -> Table;
	collect: <I,V, i,v>(t: Map<I,V>, handler: (I,V) -> (i,v) ) -> Map<i,v>;
	collectArray: <I,V, v>(t: Map<I,V>, handler: (I,V) -> v) -> Array<v>;
	collectSet: <I,V, v>(t: Map<I,V>, handler: (I,V) -> v) -> Set<v>;
	compose: <params...,returns...>(...AnyFunction) -> (params...) -> returns...;
	copy: <I,V>(Map<I,V>)->Map<I,V>;
	cycles: (t: Table, depth:number?, initcycles: Cycles?) -> Cycles?;
	endsWith: (input: string, suffix: string) -> boolean;
	filter: <I,V>(t: Map<I,V>, filterFunc: (V,I)->any?) -> Array<V>;
	find: <I,V>(t: Map<I,V>,findFunc: (V,I)->any?) -> V?;
	findIndex: <V>(t: Array<V>,findFunc: (V,number)->any?) -> number?;
	flat: <A>(t: Array<Array<A>>) -> Array<A>;
	forEach: <I,V>(t: Map<I,V>, handler: (V,I) -> any) -> nil;
	forEachArgs: <A>(handler: (a: A) -> nil, ...A) -> nil;
	format: (template: string, ...string) -> nil;
	formatValue: (val: any, display: string) -> string;
	freeze: <A>(objectname:string, t: A, throwIfMissing: boolean?) -> A;
	getOrSet: <I,V>(t: Map<I,V>, k: I, handler: (Map<I,V>, I) -> V) -> V;
	groupBy: <I,V, v>(t: Map<I,V>, getKey: string | (V,I) -> v) -> Map<v, Array<V>>;
	identity: <A...>(A...) -> A...;
	includes: <I,V>(t: Map<I,V>, needle: V) -> boolean;
	isCallable: (a: any) -> boolean;
	isLowerCase: (a: string) -> boolean;
	isUpperCase: (a: string) -> boolean;
	iterable: <I,V>(a: Map<I,V>) -> () -> (I,V);
	iterator: <A...>(a: Table | AnyFunction) -> () -> A...;
	join: <I,V>(...Map<I,V>) -> Map<I,V>;
	joinDeep: <I,V>(source: Map<I,V>, delta: Map<I,V>) -> Map<I,V>;
	keyBy: <I,V, i>(t: Map<I,V>, getKey: (V,I) -> i) -> Map<i, V>;
	keys: <I>(t: Map<I,any>) -> Array<I>;
	last: <A>(t: Array<A>, handler: ((A, number) -> true?)?) -> A;
	leftPad: (input: string, length: number, prefix: string?) -> string;
	map: <V, v>(t: Array<V>, handler: (V,number) -> v) -> Array<v>;
	mapFirst: <V, v>(t: Array<V>, handler: (V, number) -> v?) -> v?;
	mapLast: <V, v>(t: Array<V>, handler: (V, number) -> v?) -> v?;
	mapOne: <I, V, v>(t: Map<I, V>, handler: ((V, I) -> v?)?) -> v?;
	noop: () -> nil;
	omit: <I,V>(input: Map<I,V>, keys: Array<V>) -> Map<I,V>;
	pick: <I,V>(input: Map<I,V>, handler: (V,I) -> any?) -> Map<I,V>;
	pretty: (object: any, options: PrettyOptions?) -> string;
	reduce: <A,B>(arr: Array<A>, handler: (last: B, current: A, i: number) -> B, init: B) -> B;
	reverse: <A>(t: Array<A>) -> Array<A>;
	rightPad: (input:string, len: number, suffix: string?) -> string;
	shallowEqual: (left: any, right: any) -> boolean;
	slice: <A>(t: Array<A>, left: number, right: number) -> Array<A>;
	some: <I,V>(t: Map<I,V>, handler: (V,I)->any?) -> boolean;
	splitOn: (from: string, patt: string) -> Array<string>;
	startsWith: (from: string, prefix: string) -> boolean;
	trim: (input: string) -> string;
	values: <V>(t: Map<any,V>) -> Array<V>;
}

export type Array<Value> = {Value}
export type Map<Key, Value> = {[Key]: Value};
export type Set<Key> = Map<Key, boolean>
export type Table = Map<any, any>
export type AnyFunction = (...any) -> ...any
export type module = __module;

--// MAIN
local DashSingular = {} :: __module
local Objects = script.Parent
local LuaUTypes = require(Objects.LuaUTypes)
local disguise = LuaUTypes.disguise
local same = LuaUTypes.same

local class, 
	format,
	join,
	assertEqual,
	formatValue,
	pretty,
	map,
	iterator,
	None,
	forEach,
	forEachArgs,
	assign,
	cycles,
	keys,
	includes,
	append,
	slice,
	splitOn,
	startsWith
	= disguise()

local concat = table.concat
local insert = table.insert
local sort = table.sort

local __error = {}
__error.__index = __error

function __error.new(name: string, message: string, tags)
	return disguise(setmetatable({
		name = name;
		message = message or 'An error occurred';
		tags = tags or {}
	}, __error)) :: __Error
end

function __error.__tostring(self: __Error): string
	return format("{}: {}\n{}", self.name, format(self.message, self.tags), self.stack)
end

function __error.joinTags(self: __Error, tags: Table?): Error
	return __error.new(self.name, self.message, join(self.tags, tags))
end

function __error:throw(tags: Table?)
	local instance = self:joinTags(tags)
	instance.stack = debug.traceback()
	error(instance)
end

function throwNotImplemented(tags: Table)
	__error.new(
		"NotImplemented", 
		[[The method "{methodName}" is not implemented on the class "{className}"]]
	)
	:throw(tags)
end

export type Constructor = () -> Table

local defaultConstructor = function()return {}end

function class(name: string, constructor: Constructor?)
	constructor = constructor or defaultConstructor
	local Class = {
		name = name
	}
	--[[
		Return a new instance of the class, passing any arguments to the specified constructor.
		@example
			local Car = class("Car", function(speed)
				return {
					speed = speed
				}
			end)
			local car = Car.new(5)
			pretty(car) --> 'Car {speed = 5}'
	]]
	function Class.new(...)
		local instance = disguise(constructor)(...)
		setmetatable(
			instance,
			{
				__index = Class,
				__tostring = Class.toString,
				__eq = Class.equals,
				__lt = Class.__lt,
				__le = Class.__le,
				__add = Class.__add,
				__sub = Class.__sub,
				__mul = Class.__mul,
				__div = Class.__div,
				__mod = Class.__mod
			}
		)
		instance.Class = Class
		instance:_init(...)
		return instance
	end
	--[[
		Run after the instance has been properly initialized, allowing methods on the instance to
		be used.
		@example
			local Vehicle = dash.class("Vehicle", function(wheelCount) return 
				{
					speed = 0,
					wheelCount = wheelCount
				}
			end)
			-- Let's define a static private function to generate a unique id for each vehicle.
			function Vehicle._getNextId()
				Vehicle._nextId = Vehicle._nextId + 1
				return Vehicle._nextId
			end
			Vehicle._nextId = 0
			-- A general purpose init function may call other helper methods
			function Vehicle:_init()
				self._id = self:_generateId()
			end
			-- Assign an id to the new instance
			function Vehicle:_generateId()
				return format("#{}: {} wheels", Vehicle._getNextId(), self.wheelCount)
			end
			-- Return the id if the instance is represented as a string 
			function Vehicle:toString()
				return self._id
			end
			local car = Vehicle.new(4)
			tostring(car) --> "#1: 4 wheels"
	]]
	function Class:_init()
	end

	--[[
		Returns `true` if _value_ is an instance of _Class_ or any sub-class.
		@example
			local Vehicle = dash.class("Vehicle", function(wheelCount) return 
				{
					speed = 0,
					wheelCount = wheelCount
				}
			end)
			local Car = Vehicle:extend("Vehicle", function()
				return Vehicle.constructor(4)
			end)
			local car = Car.new()
			car.isInstance(Car) --> true
			car.isInstance(Vehicle) --> true
			car.isInstance(Bike) --> false
	]]
	function Class.isInstance(value)
		local ok, isInstance = pcall(function()
			local metatable = getmetatable(value)
			while metatable do
				if metatable.__index == Class then
					return true
				end
				metatable = getmetatable(metatable.__index)
			end
			return false
		end)
		return ok and isInstance
	end

	--[[
		Create a subclass of _Class_ with a new _name_ that inherits the metatable of _Class_,
		optionally overriding the _constructor_ and providing additional _decorators_.
		The super-constructor can be accessed with `Class.constructor`.
		Super methods can be accessed using `Class.methodName` and should be called with self.
		@example
			local Vehicle = dash.class("Vehicle", function(wheelCount) return 
				{
					speed = 0,
					wheelCount = wheelCount
				}
			end)
			-- Let's define a static private function to generate a unique id for each vehicle.
			function Vehicle._getNextId()
				Vehicle._nextId = Vehicle._nextId + 1
				return Vehicle._nextId
			end
			Vehicle._nextId = 0
			-- A general purpose init function may call other helper methods
			function Vehicle:_init()
				self.id = self:_generateId()
			end
			-- Assign an id to the new instance
			function Vehicle:_generateId()
				return dash.format("#{}: {} wheels", Vehicle._getNextId(), self.wheelCount)
			end
			-- Let's make a Car class which has a special way to generate ids
			local Car = Vehicle:extend("Vehicle", function()
				return Vehicle.constructor(4)
			end)
			-- Uses the super method to generate a car-specific id
			function Car:_generateId()
				self.id = dash.format("Car {}", Vehicle._generateId(self))
			end
			local car = Car.new()
			car.id --> "Car #1: 4 wheels"
	]]
	function Class:extend(name: string, constructor)
		local SubClass = class(name, constructor or Class.new)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end

	--[[
		Return a string representation of the instance. By default this is the _name_ field (or the
		Class name if this is not defined), but the method can be overridden.
		@example
			local Car = class("Car", function(name)
				return {
					name = name
				}
			end)
			
			local car = Car.new()
			car:toString() --> 'Car'
			tostring(car) --> 'Car'
			print("Hello " .. car) -->> Hello Car
			local bob = Car.new("Bob")
			bob:toString() --> 'Bob'
			tostring(bob) --> 'Bob'
			print("Hello " .. bob) -->> Hello Bob
		@example
			local NamedCar = class("NamedCar", function(name)
				return {
					name = name
				}
			end)
			function NamedCar:toString()
				return "Car called " .. self.name
			end
			local bob = NamedCar.new("Bob")
			bob:toString() --> 'Car called Bob'
			tostring(bob) --> 'Car called Bob'
			print("Hello " .. bob) -->> Hello Car called Bob
	]]
	function Class:toString()
		return self.name
	end

	--[[
		Returns `true` if `self` is considered equal to _other_. This replaces the `==` operator
		on instances of this class, and can be overridden to provide a custom implementation.
	]]
	function Class:equals(other)
		return rawequal(self, other)
	end

	--[[
		Returns `true` if `self` is considered less than  _other_. This replaces the `<` operator
		on instances of this class, and can be overridden to provide a custom implementation.
	]]
	function Class:__lt(other)
		throwNotImplemented({
			methodName = "__lt",
			className = name
		})	
	end

	--[[
		Returns `true` if `self` is considered less than or equal to _other_. This replaces the
		`<=` operator on instances of this class, and can be overridden to provide a custom
		implementation.
	]]
	function Class:__le(other)
		throwNotImplemented({
			methodName = "__le",
			className = name
		})	
	end

	function Class:__add()
		throwNotImplemented({
			methodName = "__add",
			className = name
		})	
	end
	function Class:__sub()
		throwNotImplemented({
			methodName = "__sub",
			className = name
		})	
	end
	function Class:__mul()
		throwNotImplemented({
			methodName = "__mul",
			className = name
		})	
	end
	function Class:__div()
		throwNotImplemented({
			methodName = "__div",
			className = name
		})	
	end
	function Class:__mod()
		throwNotImplemented({
			methodName = "__mod",
			className = name
		})	
	end

	return Class
end

function assertEqual(left: any, right: any, formattedErrorMessage: string?)
	if left == right then return true end;
	__error.new("AssertError", formattedErrorMessage or 
		[[Left {left:?} does not equal right {right:?}]]):throw({
		left = left,
		right = right
	})
end

function iterator(input: Table | AnyFunction): AnyFunction
	if typeof(input) == "function" then
		return input
	elseif typeof(input) == "table" then
		if #input > 0 then
			return ipairs(input)
		else
			return pairs(input)
		end
	else
		return disguise()
	end
end

function map<A, a>(input: Array<A>, handler: __itHandler<A, number, a>): Array<a>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.map with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.map with argument #2 of type {left:?} not {right:?}]])
	local result = {}
	for key, child in iterator(input) do
		local value = handler(child, key)
		assertEqual(value == nil, false, [[Returned nil from a Dash.map handler]])
		result[key] = value
	end
	return result
end

local function indentLines(lines: Array<string>, indent: string)
	return map(lines, function(line: string)
		return indent .. line
	end)
end

function forEach<I, V>(input: Map<I, V>, handler: __itHandler<V, I, any?>)
	assertEqual(typeof(input), "table", [[Attempted to call Dash.forEach with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.forEach with argument #2 of type {left:?} not {right:?}]])
	for key, value in iterator(input) do
		handler(value, key)
	end
end

function forEachArgs<A>(handler: __itHandler<A, number, any?>, ...: A)
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.forEachArgs with argument #1 of type {left:?} not {right:?}]])
	for index = 1, select('#', ...) do
		handler(select(index, ...), index)
	end
end

function assign(target: Table, ...: Table): Table
	assertEqual(typeof(target), "table", [[Attempted to call Dash.assign with argument #1 of type {left:?} not {right:?}]])
	-- Iterate through the varags in order
	forEachArgs(function(input: Table?)
		-- Ignore items which are not defined
		if input == nil or input == None then return end
		-- Iterate through each key of the input and assign to target at the same key
		forEach(input, function(value, key)
			if value == None then
				target[key] = nil
			else
				target[key] = value
			end
		end)
	end, ...)
	return target
end

local function getDefaultCycles(): Cycles
	return {
		visited = {},
		refs = {},
		nextRef = 1,
		omit = {},
	}
end

function keys<A>(input: Map<A, any>): Array<A>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.keys with argument #1 of type {left:?} not {right:?}]])
	local result = {}
	for key in iterator(input) do
		insert(result, key)
	end
	return result
end

function includes<I, V>(input: Map<I, V>, item: V): boolean
	assertEqual(typeof(input), "table", [[Attempted to call Dash.includes with argument #1 of type {left:?} not {right:?}]])
	if item == nil then return false end
	for _, child in pairs(input) do
		if child == item then
			return true
		end
	end
	return false
end

function cycles(input: any, depth: number?, initialCycles: any): Cycles?
	if depth == -1 then return initialCycles end
	if typeof(input) ~= "table" then return end
	
	local childCycles = initialCycles or getDefaultCycles()

	if childCycles.visited[input] then
		-- We have already visited the table, so check if it has a reference
		if not childCycles.refs[input] then
			-- If not, create one as it is present at least twice
			childCycles.refs[input] = childCycles.nextRef
			childCycles.nextRef += 1
		end
		
		return
	end
	
	-- We haven't yet visited the table, so recurse
	childCycles.visited[input] = true
	-- Visit in order to preserve reference consistency
	local inputKeys = keys(input)
	sort(inputKeys, function(left, right)
		if typeof(left) == "number" and typeof(right) == "number" then
			return left < right
		else
			return tostring(left) < tostring(right)
		end
	end)
	
	for _, key in ipairs(inputKeys) do
		if includes(childCycles.omit, key) then
			-- Don't visit omitted keys
			continue
		end
		
		local value = input[key]
		
		-- TODO Luau: support type narrowring with "and"
		-- TYPED: cycles(key, depth and depth - 1 or nil, childCycles)
		-- TYPED: cycles(value, depth and depth - 1 or nil, childCycles)
		-- Recurse through both the keys and values of the table
		if depth then
			cycles(key, depth - 1, childCycles)
			cycles(value, depth - 1, childCycles)
		else
			cycles(key, nil, childCycles)
			cycles(value, nil, childCycles)
		end
	end

	return childCycles
end

function append<A>(target: Array<A>, ...: A): Array<A>
	assertEqual(typeof(target), "table", [[Attempted to call Dash.append with argument #1 of type {left:?} not {right:?}]])
	forEachArgs(function(list: Table?)
		if list == None or list == nil then return end
		forEach(list, function(value: any)
			insert(target, value)
		end)
	end, ...)
	return target
end

function slice<A>(input: Array<A>, left: number?, right: number?): Array<A>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.slice with argument #1 of type {left:?} not {right:?}]])
	local output = {}

	-- Default values
	local l = left or 1
	local r = right or #input
	assertEqual(typeof(left), "number", [[Attempted to call Dash.slice with argument #2 of type {left:?} not {right:?}]])
	assertEqual(typeof(right), "number", [[Attempted to call Dash.slice with argument #3 of type {left:?} not {right:?}]])

	if l < 0 then l += #input end
	if r and r < 0 then r += #input end
	for i = l, r do
		insert(output, input[i])
	end
	
	return output
end

local function prettyLines(object: any, options: any): Array<string>
	options = options or {}
	if type(object) == "table" then
		-- A table needs to be serialized recusively
		-- Construct the options for recursive calls for the table values
		local valueOptions = assign({
			visited = {},
			indent = "\t",
			depth = 2
		}, options, {
			-- Depth is reduced until we shouldn't recurse any more
			depth = options.depth and options.depth - 1 or nil,
			cycles = options.cycles or cycles(object, options.depth, {
				visited = {},
				refs = {},
				nextRef = 0,
				depth = options.depth,
				omit = options.omit or {}
			})
		})
		
		-- Indicate there is more information available beneath the maximum depth
		if valueOptions.depth == -1 then return {"..."}end
		
		-- Indicate this table has been printed already, so print a ref number instead of
		-- printing it multiple times
		if valueOptions.visited[object] then 
			return {`&{valueOptions.cycles.refs[object]}`}
		end

		valueOptions.visited[object] = true

		local multiline = valueOptions.multiline
		local comma = multiline and "," or ", "

		-- If the table appears multiple times in the output, mark it with a ref prefix so it can
		-- be identified if it crops up later on
		local ref = valueOptions.cycles.refs[object]
		local refTag = ref and ("<%s>"):format(ref) or ""
		local lines = {refTag .. "{"}

		-- Build the options for the recursive call for the table keys
		local keyOptions = join(valueOptions, {
			noQuotes = true,
			multiline = false
		})

		-- Compact numeric keys into a simpler array style
		local maxConsecutiveIndex = 0
		local first = true
		for index, value in ipairs(object) do
			-- Don't include keys which are omitted
			if valueOptions.omit and includes(valueOptions.omit, index) then continue end
			if first then
				first = false
			else
				lines[#lines] ..= comma
			end
			if valueOptions.multiline then
				local indendedValue = indentLines(prettyLines(value, valueOptions), valueOptions.indent)
				append(lines, indendedValue)
			else
				lines[#lines] ..= pretty(value, valueOptions)
			end
			maxConsecutiveIndex = index
		end
		if #object > 0 and valueOptions.arrayLength then
			lines[1] = ("#%d %s"):format(#object, lines[1])
		end
		-- Ensure keys are printed in order to guarantee consistency
		local objectKeys = keys(object)
		sort(objectKeys, function(left, right)
			if typeof(left) == "number" and typeof(right) == "number" then
				return left < right
			else
				return tostring(left) < tostring(right)
			end
		end)
		for _, key in ipairs(objectKeys) do
			local value = object[key]
			-- We printed a key if it's an index e.g. an integer in the range 1..n.
			if typeof(key) == "number" and 
				key % 1 == 0 and key >= 1 and key <= maxConsecutiveIndex then
				continue
			end
			-- Don't include keys which are omitted
			if valueOptions.omit and includes(valueOptions.omit, key) then
				continue
			end
			if first then
				first = false
			else
				lines[#lines] ..= comma
			end
			if valueOptions.multiline then
				local keyLines = prettyLines(key, keyOptions)
				local indentedKey = indentLines(keyLines, valueOptions.indent)
				local valueLines = prettyLines(value, valueOptions)
				local valueTail = slice(valueLines, 2)
				local indendedValueTail = indentLines(valueTail, valueOptions.indent)
				-- The last line of the key and first line of the value are concatenated together
				indentedKey[#indentedKey] = ("%s = %s"):format(indentedKey[#indentedKey], valueLines[1])
				append(lines, indentedKey, indendedValueTail)
			else
				lines[#lines] = ("%s%s = %s"):format(lines[#lines], pretty(key, keyOptions), pretty(value, valueOptions))
			end
		end
		if valueOptions.multiline then
			if first then
				-- An empty table is just represented as {}
				lines[#lines] ..= "}"
			else
				insert(lines, "}")
			end
		else
			lines[#lines] = ("%s}"):format(lines[#lines])
		end
		return lines
	elseif type(object) == "string" and not options.noQuotes then
		return {('"%s"'):format(object)}
	else
		return {tostring(object)}
	end
end

function pretty(object: any, options: any): string
	return concat(prettyLines(object, options), "\n")
end

function formatValue(value: any, displayString: string): string
	displayString = displayString or ""
	assertEqual(
		typeof(displayString), 
		"string", 
		[[Attempted to call Dash.formatValue with argument #2 of type {left:?} not {right:?}]]
	)
	-- Inline require to prevent infinite require cycle
	local displayTypeStart, displayTypeEnd = displayString:find("[A-Za-z#?]+")
	
	if displayTypeStart then
		local displayType = displayString:sub(displayTypeStart, displayTypeEnd)
		local formatAsString =
			`%{displayString:sub(1, displayTypeStart - 1)}{
			displayString:sub(displayTypeEnd + 1)}s`

		-- Pretty print values
		if displayType == "#?" then
			-- Multiline print a value
			return formatAsString:format(pretty(value, {multiline = true}))
		elseif displayType == "?" then
			-- Inspect a value
			return formatAsString:format(pretty(value))
		end
		return (`%{displayString}`):format(value)
	else
		local displayType = "s"
		if type(value) == "number" then
			-- Correctly display floats or integers
			local _, fraction = math.modf(value)
			displayType = fraction == 0 and "d" or "f"
		end
		return (`%{displayString}{displayType}`):format(tostring(value))
	end
end

function splitOn(input: string, pattern: string): Array<string>
	assertEqual(typeof(input), "string", [[Attempted to call Dash.splitOn with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(pattern), "string", [[Attempted to call Dash.splitOn with argument #2 of type {left:?} not {right:?}]])
	local parts = {}
	local delimiters = {}
	local from = 1
	if not pattern then
		for i = 1, #input do
			insert(parts, input:sub(i, i))
		end
		return parts
	end
	local delimiterStart, delimiterEnd = input:find(pattern, from)
	while delimiterStart do
		insert(delimiters, input:sub(delimiterStart, delimiterEnd))
		insert(parts, input:sub(from, delimiterStart - 1))
		from = delimiterEnd + 1
		delimiterStart, delimiterEnd = input:find(pattern, from)
	end
	insert(parts, input:sub(from))
	return parts, delimiters
end

function startsWith(input: string, prefix: string): boolean
	assertEqual(typeof(input), "string", [[Attempted to call Dash.startsWith with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(prefix), "string", [[Attempted to call Dash.startsWith with argument #2 of type {left:?} not {right:?}]])
	return input:sub(1, prefix:len()) == prefix
end

function format(formatString: string, ...)
	assertEqual(typeof(formatString), "string", [[Attempted to call Dash.format with argument #1 of type {left:?} not {right:?}]])
	local args = {...}
	local argIndex = 1
	local texts, subs = splitOn(formatString, "{[^{}]*}")
	local result = {}
	-- Iterate through possible curly-brace matches, ignoring escaped and substituting valid ones
	for i, text in pairs(texts) do
		local unescaped = text:gsub("{{", "{"):gsub("}}", "}")
		insert(result, unescaped)
		local placeholder = subs[i] and subs[i]:sub(2, -2)
		if placeholder then
			-- Ensure that the curly braces have not been escaped
			local escapeMatch = text:gmatch("{+$")()
			local isEscaped = escapeMatch and #escapeMatch % 2 == 1
			if not isEscaped then
				-- Split the placeholder into left & right parts pivoting on the central ":"
				local placeholderSplit = splitOn(placeholder, ":")
				local isLength = startsWith(placeholderSplit[1], "#")
				local argString = isLength and placeholderSplit[1]:sub(2) or placeholderSplit[1]
				local nextIndex = tonumber(argString)
				local displayString = placeholderSplit[2]
				local arg = "nil"
				if nextIndex then
					-- Return the next argument
					arg = args[nextIndex]
				elseif argString:len() > 0 then
					-- Print a child key of the 1st argument
					local argChild = args[1] and args[1][argString]
					if argChild ~= nil then
						arg = argChild
					end
				else
					arg = args[argIndex]
					argIndex += 1
				end
				if isLength then
					arg = #arg
				end
				-- Format the selected value
				insert(result, formatValue(arg, displayString or ""))
			else
				local unescapedSub = placeholder
				insert(result, unescapedSub)
			end
		end
	end
	return concat(result, "")
end

function join<I, V>(...: Map<I,V>): Map<I, V>return assign({}, ...)end

-- other functions
function collect<I,V, i,v>(input: Map<I,V>, handler: (I,V) -> (i,v)): Map<i, v>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.collect with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.collect with argument #2 of type {left:?} not {right:?}]])
	local result = {}
	for key, child in iterator(input) do
		local outputKey, outputValue = handler(key, child)
		if outputKey ~= nil then
			result[outputKey] = outputValue
		end
	end
	return result
end

function collectArray<I,V, v>(input: Map<I,V>, handler: (I,V) -> v): Array<v>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.collectArray with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.collectArray with argument #2 of type {left:?} not {right:?}]])
	local result = {}
	for key, child in iterator(input) do
		local outputValue = handler(key, child)
		if outputValue ~= nil then
			insert(result, outputValue)
		end
	end
	return result
end

function collectSet<I,V, v>(input: Map<I,V>, handler: ((I,V) -> v)?): Set<v>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.collectSet with argument #1 of type {left:?} not {right:?}]])
	local result = {}
	for key, child in iterator(input) do
		local outputValue
		if handler == nil then
			outputValue = child 
		else
			outputValue = handler(key, child)
		end
		if outputValue ~= nil then
			result[outputValue] = true
		end
	end
	return result
end

function compose<params...,returns...>(...: AnyFunction): ((params...) -> returns...)
	local fns = {...}
	if #fns == 0 then return disguise(LuaUTypes.same) end
	return function(...)
		local result = {fns[1](...)}
		for i = 2, #fns do
			result = {fns[i](unpack(result))}
		end
		return unpack(result)
	end
end

function copy<I,V>(input: Map<I,V>): Map<I,V>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.copy with argument #1 of type {left:?} not {right:?}]])
	return join(input)
end

function endsWith(input: string, suffix: string)
	assertEqual(typeof(input), "string", [[Attempted to call Dash.endsWith with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(suffix), "string", [[Attempted to call Dash.endsWith with argument #2 of type {left:?} not {right:?}]])
	return input:sub(-suffix:len()) == suffix
end

function filter<I,V>(input: Map<I,V>, handler: (V,I)->any?): Array<V>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.filter with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.filter with argument #2 of type {left:?} not {right:?}]])
	local result = {}
	for index, child in iterator(input) do
		if handler(child, index) then
			table.insert(result, child)
		end
	end
	return result
end

function find<I,V>(input: Map<I,V>, handler: (V,I)->any?): V?
	assertEqual(typeof(input), "table", [[Attempted to call Dash.find with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.find with argument #2 of type {left:?} not {right:?}]])
	for key, child in iterator(input) do
		if handler(child, key) then
			return child
		end
	end
	
	return nil
end

function findIndex<V>(input: Array<V>, handler: (V, number)->any?): number?
	assertEqual(typeof(input), "table", [[Attempted to call Dash.findIndex with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.findIndex with argument #2 of type {left:?} not {right:?}]])
	for key, child in ipairs(input) do
		if handler(child, key) then
			return key
		end
	end
	
	return nil
end

function flat<A>(input: Array<Array<A>>): Array<A>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.flat with argument #1 of type {left:?} not {right:?}]])
	local result = {}
	forEach(input, function(childArray: Array<A>)
		append(result, childArray)
	end)
	return result
end

local ReadonlyKey = __error.new(
	"ReadonlyKey", 
	"Attempted to write to readonly key {key:?} of frozen object {objectName:?}"
)
local MissingKey = __error.new(
	"MissingKey", 
	"Attempted to read missing key {key:?} of frozen object {objectName:?}"
)

-- TYPED: local function freeze<T extends Types.Table>(objectName: string, object: T, throwIfMissing: boolean?): T
function freeze<A>(objectName: string, object: A, throwIfMissing: boolean?): A
	assertEqual(typeof(objectName), "string", [[Attempted to call Dash.freeze with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(object), "table", [[Attempted to call Dash.freeze with argument #2 of type {left:?} not {right:?}]])
	
	local __object = disguise(object)
	-- We create a proxy so that the underlying object is not affected
	local proxy = {}
	setmetatable(
		proxy,
		{
			__index = function(_, key: any)
				local value = __object[key]
				if value == nil and throwIfMissing then
					-- Tried to read a key which isn't present in the underlying object
					MissingKey:throw({
						key = key,
						objectName = objectName
					})
				end
				return value
			end,
			__newindex = function(_, key: any)
				-- Tried to write to any key
				ReadonlyKey:throw({
					key = key,
					objectName = objectName
				})
			end,
			__len = function()return #__object;end,
			__tostring = function()return format("Frozen({})", objectName)end,
			-- TODO Luau: Gated check for if a function has a __call value
			__call = function(_, ...)return __object(...)end
		}
	)
	return disguise(proxy)
end

function getOrSet<I,V>(input: Map<I,V>, key: I, getValue: (Map<I,V>, I) -> V): V
	assertEqual(typeof(input), "table", [[Attempted to call Dash.getOrSet with argument #1 of type {left:?} not {right:?}]])
	assertEqual(key == nil, false, [[Attempted to call Dash.getOrSet with a nil key argument]])
	assertEqual(typeof(getValue), "function", [[Attempted to call Dash.getOrSet with argument #3 of type {left:?} not {right:?}]])
	if input[key] == nil then
		input[key] = getValue(input, key)
	end
	return input[key]
end

function groupBy<I,V, v>(input: Map<I,V>, getKey: string | ((V,I) -> v)): Map<v, Array<V>>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.groupBy with argument #1 of type {left:?} not {right:?}]])
	assertEqual(getKey == nil, false, [[Attempted to call Dash.groupBy with a nil getKey argument]])
	local result = {}
	for key, child in pairs(input) do
		local groupKey = if typeof(getKey) == "function" then
			getKey(child, key)
		else
			child[getKey]
		
		if groupKey == nil then continue; end
		
		if result[groupKey] ~= nil then
			insert(result[groupKey], child)
		else
			result[groupKey] = {child}
		end
	end
	return result
end

function isCallable(value: any): boolean
	return type(value) == "function" or
		(type(value) == "table" and getmetatable(value) and getmetatable(value).__call ~= nil) 	
		or false
end

function isLowercase(input: string)
	assertEqual(typeof(input), "string", [[Attempted to call Dash.isLowercase with argument #1 of type {left:?} not {right:?}]])
	assertEqual(#input > 0, true, [[Attempted to call Dash.isLowercase with an empty string]])
	local firstLetter = input:sub(1, 1)
	return firstLetter == firstLetter:lower()
end

function isUppercase(input: string)
	assertEqual(typeof(input), "string", [[Attempted to call Dash.isUppercase with argument #1 of type {left:?} not {right:?}]])
	assertEqual(#input > 0, true, [[Attempted to call Dash.isUppercase with an empty string]])
	local firstLetter = input:sub(1, 1)
	return firstLetter == firstLetter:upper()
end

function iterable<I,V>(input: Map<I,V>): (() -> (I,V))
	local currentIndex = 1
	local inOrderedKeys = true
	local currentKey
	local iterateFn
	
	iterateFn = function()
		if inOrderedKeys then
			local value = input[currentIndex]
			if value == nil then
				inOrderedKeys = false
			else
				local index = currentIndex
				currentIndex += 1
				return index, value
			end
		end
		while true do
			currentKey = next(input, currentKey)
			-- Don't re-visit ordered keys 1..n
			if typeof(currentKey) == "number" and currentKey > 0 and currentKey < currentIndex and currentKey % 1 == 0 then
				continue
			end
			if currentKey == nil then
				return nil
			else
				return currentKey, input[disguise(currentKey)]
			end
		end
	end
	return iterateFn
end

function joinDeep<I,V>(source: Map<I,V>, delta: Map<I,V>): Map<I,V>
	assertEqual(typeof(source), "table", [[Attempted to call Dash.joinDeep with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(delta), "table", [[Attempted to call Dash.joinDeep with argument #2 of type {left:?} not {right:?}]])
	local result = copy(source)
	-- Iterate through each key of the input and assign to target at the same key
	forEach(delta, function(value, key)
		result[key] = if typeof(source[key]) == "table" and typeof(value) == "table" then
				-- Only merge tables
				joinDeep(disguise(source[key]), value)
			elseif value == None then
				-- Remove none values
				nil
			else
				value
	end)
	return result
end

function keyBy<I,V, i>(input: Map<I,V>, getKey: ((V,I) -> i)): Map<i, V>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.keyBy with argument #1 of type {left:?} not {right:?}]])
	assertEqual(getKey == nil, false, [[Attempted to call Dash.keyBy with a nil getKey argument]])

	return collect(input, function(key, child)
		local newKey = if typeof(getKey) == "function" then
			getKey(child, key)
		else
			child[getKey]
		
		return newKey, child
	end)
end

function last<A>(input: Array<A>, handler: ((A, number) -> true?)?): A
	assertEqual(typeof(input), "table", [[Attempted to call Dash.last with argument #1 of type {left:?} not {right:?}]])
	for index = #input, 1, -1 do
		local child = input[index]
		
		if not handler or handler(child, index) then
			return child
		end
	end
	
	return disguise()
end

function leftPad(input: string, length: number, prefix: string?): string
	assertEqual(typeof(input), "string", [[Attempted to call Dash.leftPad with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(length), "number", [[Attempted to call Dash.leftPad with argument #2 of type {left:?} not {right:?}]])

	local definedPrefix = prefix or " "
	assertEqual(typeof(definedPrefix), "string", [[Attempted to call Dash.leftPad with argument #3 of type {left:?} not {right:?}]])

	local padLength = length - input:len()
	local remainder = padLength % definedPrefix:len()
	local repetitions = (padLength - remainder) / definedPrefix:len()
	return string.rep(definedPrefix or " ", repetitions) .. definedPrefix:sub(1, remainder) .. input
end

function mapFirst<V, v>(input: Array<V>, handler: __itHandler<V, number, v?>): v?
	assertEqual(typeof(input), "table", [[Attempted to call Dash.mapFirst with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.mapFirst with argument #2 of type {left:?} not {right:?}]])
	for index, child in ipairs(input) do
		local output = handler(child, index)
		if output ~= nil then
			return output
		end
	end
	return disguise()
end

function mapLast<V, v>(input: Array<V>, handler: __itHandler<V, number, v?>): v?
	assertEqual(typeof(input), "table", [[Attempted to call Dash.mapLast with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.mapLast with argument #2 of type {left:?} not {right:?}]])
	for key = #input, 1, -1 do
		local child = input[key]
		local output = handler(child, key)
		if output ~= nil then
			return output
		end
	end
	
	return disguise()
end

function mapOne<I, V, v>(input: Map<I, V>, handler: __itHandler<V, I, v>?): v?
	assertEqual(typeof(input), "table", [[Attempted to call Dash.mapOne with argument #1 of type {left:?} not {right:?}]])
	for key, child in pairs(input) do
		local output
		if handler then
			output = handler(child, key)
		else
			output = child
		end
		if output ~= nil then
			return output
		end
	end
	
	return disguise()
end

function omit<I, V>(input: Map<I,V>, keys: Array<V>): Map<I,V>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.omit with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(keys), "table", [[Attempted to call Dash.omit with argument #2 of type {left:?} not {right:?}]])
	local output = {}
	local keySet = collectSet(keys)
	-- TYPED: forEach(input, function(child: Value, key: Key)
	forEach(input, function(child, key)
		if not keySet[key] then
			output[key] = input[key]
		end
	end)
	return output
end

function pick<I,V>(input: Map<I,V>, handler: __itHandler<V, I, any?>): Map<I,V>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.pick with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.pick with argument #2 of type {left:?} not {right:?}]])
	local result = {}
	for key, child in iterator(input) do
		if handler(child, key) then
			result[key] = child
		end
	end
	return result
end

function reduce<A,B>(input: Array<A>, 
	handler: ((last: B, current: A, i: number) -> B), initial: B): B
	assertEqual(typeof(input), "table", [[Attempted to call Dash.reduce with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.reduce with argument #2 of type {left:?} not {right:?}]])
	local result = initial
	for i = 1, #input do
		result = handler(result, input[i], i)
	end
	return result
end

function reverse<A>(input: Array<A>): Array<A>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.reverse with argument #1 of type {left:?} not {right:?}]])
	local output = {}
	for i = #input, 1, -1 do
		insert(output, input[i])
	end
	return output
end

function rightPad(input: string, length: number, suffix: string?): string
	assertEqual(typeof(input), "string", [[Attempted to call Dash.rightPad with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(length), "number", [[Attempted to call Dash.rightPad with argument #2 of type {left:?} not {right:?}]])

	local definedSuffix = suffix or " "
	assertEqual(typeof(definedSuffix), "string", [[Attempted to call Dash.rightPad with argument #3 of type {left:?} not {right:?}]])

	local padLength = length - input:len()
	local remainder = padLength % definedSuffix:len()
	local repetitions = (padLength - remainder) / definedSuffix:len()
	return input .. string.rep(suffix or " ", repetitions) .. definedSuffix:sub(1, remainder)
end

function shallowEqual(left: any, right: any)
	if left == right then
		return true
	end
	if typeof(left) ~= "table" or typeof(right) ~= "table" or #left ~= #right then
		return false
	end
	if left == nil or right == nil then
		return false
	end
	for key, value in pairs(left) do
		if right[key] ~= value then
			return false
		end
	end
	for key, value in pairs(right) do
		if left[key] ~= value then
			return false
		end
	end
	return true
end

function some<I,V>(input: Map<I,V>, handler: __itHandler<V, I, any?>): boolean
	assertEqual(typeof(input), "table", [[Attempted to call Dash.some with argument #1 of type {left:?} not {right:?}]])
	assertEqual(typeof(handler), "function", [[Attempted to call Dash.some with argument #2 of type {left:?} not {right:?}]])
	for key, child in pairs(input) do
		if handler(child, key) then
			return true
		end
	end
	return false
end

function trim(input: string): string
	assertEqual(typeof(input), "string", [[Attempted to call Dash.trim with argument #1 of type {left:?} not {right:?}]])
	return disguise(input:match("^%s*(.-)%s*$"))
end

function values<V>(input: Map<any,V>): Array<V>
	assertEqual(typeof(input), "table", [[Attempted to call Dash.values with argument #1 of type {left:?} not {right:?}]])
	local result = {}
	for _, value in iterator(input) do
		insert(result, value)
	end
	return result
end

--// Symbol section for NONE
local Symbol = class("Symbol", function(name: string)
	return {
		name = name
	}
end)

function Symbol:toString(): string return ("Symbol(%s)"):format(self.name)end

None = Symbol.new("None")

--// Library
-- methods
DashSingular.append = append
DashSingular.assertEqual = assertEqual
DashSingular.assign = assign
DashSingular.collect = collect
DashSingular.collectArray = collectArray
DashSingular.collectSet = collectSet;
DashSingular.compose = compose;
DashSingular.cycles = cycles
DashSingular.endsWith = endsWith;
DashSingular.filter = filter;
DashSingular.find = find;
DashSingular.findIndex = findIndex;
DashSingular.flat = flat;
DashSingular.freeze = freeze;
DashSingular.getOrSet = getOrSet
DashSingular.groupBy = groupBy;
DashSingular.identity = same
DashSingular.includes = includes
DashSingular.isCallable = isCallable
DashSingular.isLowercase = isLowercase
DashSingular.isUppercase = isUppercase
DashSingular.iterable = iterable
DashSingular.iterator = iterator
DashSingular.join = join
DashSingular.joinDeep = joinDeep
DashSingular.keyBy = keyBy
DashSingular.keys = keys
DashSingular.last = last;
DashSingular.leftPad = leftPad
DashSingular.map = map
DashSingular.mapFirst = mapFirst
DashSingular.mapLast = mapLast
DashSingular.mapOne = mapOne
DashSingular.noop = LuaUTypes.empty
DashSingular.omit = omit
DashSingular.pick = pick
DashSingular.pretty = pretty
DashSingular.reduce = reduce
DashSingular.reverse = reverse
DashSingular.rightPad = rightPad
DashSingular.shallowEqual = shallowEqual
DashSingular.slice = slice
DashSingular.some = some
DashSingular.splitOn = splitOn
DashSingular.startsWith = startsWith
DashSingular.trim = trim
DashSingular.values = values

-- classes
DashSingular.class = class

DashSingular.Error = disguise(__error) :: ErrorClass
DashSingular.Symbol = Symbol

-- objects
DashSingular.None = None

return DashSingular :: __module
