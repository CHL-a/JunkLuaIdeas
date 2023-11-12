--[[
	Referal: https://github.com/Roblox/dash
		roblox.com/library/15239197565
--]]

local DashModuleScript = script.Parent.Dash
local Types = require(DashModuleScript.Types)

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
	} & Types.Class<Object>

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
	tags: Types.Map<string, any>?;
	
	joinTags: (self:__Error, Types.Table?) -> __Error;
	throw:(self:__Error, Types.Table?) -> nil;
} & __object
export type Error = __Error

type __ErrorClass = __class<'Error', __Error, (string, string, Types.Table?)>
export type ErrorClass = __ErrorClass

-- Symbol
export type SymbolClass = __class<"Symbol", __object, string>

-- cycles
local cycles = require(DashModuleScript.cycles)

export type Cycles = {
	-- A set of tables which were visited recursively
	visited: Types.Set<Types.Table>,
	-- A map from table to unique index in visit order
	refs: Types.Map<Types.Table, number>,
	-- The number to use for the next unique table visited
	nextRef: number,
	-- An array of keys which should not be visited
	omit: Types.Array<any>,
}

-- pretty
export type PrettyOptions = {
	-- The maximum depth of ancestors of a table to display (default = 2)
	depth: number?,
	-- An array of keys which should not be visited
	omit: Types.Array<any>?,
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
	visited: Types.Set<Types.Table>?,
	-- A cycles object returned from `cycles` to aid reference display
	cycles: cycles.Cycles?,
}

-- main module
type __module = {
	class: classReturn;
	Error: __ErrorClass;
	Symbol: SymbolClass;
	None: __object;
	
	append: <A>(Array<A>, ...Args<A>) -> Array<A>;
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
	findIndex: <I,V>(t: Map<I,V>,findFunc: (V,I)->any?) -> I?;
	flat: <A>(t: Array<Array<A>>) -> Array<A>;
	forEach: <I,V>(t: Map<I,V>, handler: (V,I) -> any) -> nil;
	forEachArgs: <A>(handler: (a: A) -> nil, ...A) -> nil;
	format: (template: string, ...string) -> nil;
	formatValue: (val: any, display: string) -> string;
	freeze: (objectname:string, t: Table, throwIfMissing: boolean?) -> nil;
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
	mapFirst: <V, v>(t: Array<V>, handler: (V, number) -> v?) -> v;
	mapLast: <V, v>(t: Array<V>, handler: (V, number) -> v?) -> v;
	mapOne: <I, V, v>(t: Map<I, V>, handler: ((V, I) -> v?)?) -> v;
	noop: () -> nil;
	omit: <I,V>(input: Map<I,V>, keys: Array<V>) -> Map<I,V>;
	pick: <I,V>(input: Map<I,V>, handler: (V,I) -> any?) -> Map<I,V>;
	pretty: (object: any, options: PrettyOptions?) -> string;
	reduce: <A, B>(arr: Array<A>, handler: (last: B, current: A, i: number) -> B, init: B) -> B;
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

export type Array<Value> = Types.Array<Value>
export type Args<Value> = Types.Args<Value>
export type Map<Key, Value> = Types.Map<Key, Value>
export type Set<Key> = Types.Set<Key>
export type Table = Types.Table
export type Class<Object> = Types.Class<Object>
export type AnyFunction = Types.AnyFunction
export type module = __module;

return true
