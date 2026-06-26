local AssetService = require('./@CHL>AssetService')
local Promise = require('./@CHL>Promise')
local LuaULibs = require('./LuaULibs')

type promise<T> = Promise.modified_object<T>

export type array<T> = {T}
export type map<K, V> = {[K]: V};
export type set<T> = map<T, boolean>
export type table = map<any, any>
export type any_function = (...any) -> ...any

-- class
export type class<
	class_name,
	object,
	constructor_args...
	> = {
	name: class_name;

	-- creates object, uses constructor upfront
	new: (constructor_args...) -> object;

	-- init function for class, functionally the same for argument constructor but
	-- finishes set up upon metatable set up
	_init: (self:object, constructor_args...) -> ();

	-- checks of value a contains strictly this class by checking its class and all 
	-- classes below.
	isInstance: (a: any) -> boolean;

	-- creates a subclass from class, because of now type checking works, extend is
	-- deparameterized. consider using a type in tangent for type checking.
	extend: (name: string, (...any) -> any) -> any;

	tostring: (self:object) -> string;
	equals: (self:object, other: any) -> boolean;

	-- all metamethods.
	__lt: (self:object, other: object) -> boolean;
	__le: (self:object, other: object) -> boolean;
	__add: (self:object, other: object) -> boolean;
	__sub: (self:object, other: object) -> boolean;
	__mul: (self:object, other: object) -> boolean;
	__div: (self:object, other: object) -> boolean;
	__mod: (self:object, other: object) -> boolean;
}

export type object = {
	name: string;
	tostring: (self:object) -> string;
	equals: (self:object, other: any) -> boolean;
}

-- Error
export type error = {
	name: string;
	message: string;
	tags: map<string, any>?;
	stack: string;

	joinTags: (self: error, table?) -> error;
	throw:(self: error, table?) -> ();
} & object

export type error_class = class<'Error', error, (string, string, table?)>

-- Symbol
export type symbol_class = class<"Symbol", object, string>

-- cycles
export type cycles = {
	-- A set of tables which were visited recursively
	visited: set<table>,
	-- A map from table to unique index in visit order
	refs: map<table, number>,
	-- The number to use for the next unique table visited
	nextRef: number,
	-- An array of keys which should not be visited
	omit: array<any>,
}

-- pretty
export type pretty_options = {
	-- The maximum depth of ancestors of a table to display (default = 2)
	depth: number?,
	-- An array of keys which should not be visited
	omit: array<any>?,
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
	visited: set<table>?,
	-- A cycles object returned from `cycles` to aid reference display
	cycles: cycles?,
}

-- handlers
type iterator_handler<V, I, v> = (V, I) -> v;

-- iterable
export type iterator_function<A...> = (...any) -> (A...)

export type iterable<I, V> = map<I, V> | iterator_function<I, V>

-- main module
export type module = {
	class:  <name, object, args...>(name: string, args...) -> class<name, object, args...>;
	Error: error_class;
	Symbol: symbol_class;
	None: object;

	append: <A>(array<A>, ...iterable<any, A>) -> array<A>;
	assertEqual: (left: any, right: any, msg: string?) -> ();
	assert_equal: (left: any, right: any, msg: string?) -> ();
	assign: <I, V>(t: map<I, V>, ...iterable<I, V>) -> map<I, V>;
	collect: <I,V, i,v>(t: iterable<I,V>, handler: (I,V) -> (i,v) ) -> map<i,v>;
	collectArray: <I,V, v>(t: iterable<I,V>, handler: (I,V) -> v) -> array<v>;
	collect_array: <I,V, v>(t: iterable<I,V>, handler: (I,V) -> v) -> array<v>;
	collectSet: <I,V, v>(t: iterable<I,V>, handler: (I,V) -> v) -> set<v>;
	collect_set: <I,V, v>(t: iterable<I,V>, handler: (I,V) -> v) -> set<v>;
	--// Current issue: find generic compatible version of compose
	-- compose: <params...,returns...>(...AnyFunction) -> (params...) -> returns...;
	compose: <params...,returns...>(...any) -> (params...) -> returns...;
	
	copy: <I,V>(iterable<I,V>)->map<I,V>;
	cycles: (t: table, depth:number?, initcycles: cycles?) -> cycles?;
	endsWith: (input: string, suffix: string) -> boolean;
	ends_with: (input: string, suffix: string) -> boolean;
	filter: <I,V>(t: iterable<I,V>, filterFunc: (V,I)->any?) -> array<V>;
	find: <I,V>(t: iterable<I,V>,findFunc: (V,I)->any?) -> V?;
	findIndex: <V>(t: array<V>,findFunc: (V,number)->any?) -> number?;
	find_index: <V>(t: array<V>,findFunc: (V,number)->any?) -> number?;
	flat: <A>(t: array<array<A>>) -> array<A>;
	forEach: <I, V>(t: iterable<I,V>, handler: iterator_handler<V, I, any?>) -> ();
	for_each: <I, V>(t: iterable<I,V>, handler: iterator_handler<V, I, any?>) -> ();
	forEachArgs: <A>(handler: (a: A) -> (), ...A) -> ();
	for_each_args: <A>(handler: (a: A) -> (), ...A) -> ();
	format: (template: string, ...string) -> ();
	formatValue: (val: any, display: string) -> string;
	format_value: (val: any, display: string) -> string;
	freeze: <A>(objectname:string, t: A, throwIfMissing: boolean?) -> A;
	getOrSet: <I,V>(t: map<I,V>, k: I, handler: (map<I,V>, I) -> V) -> V;
	get_or_set: <I,V>(t: map<I,V>, k: I, handler: (map<I,V>, I) -> V) -> V;
	groupBy: <I,V, v>(t: map<I,V>, getKey: string | (V,I) -> v) -> map<v, array<V>>;
	group_by: <I,V, v>(t: map<I,V>, getKey: string | (V,I) -> v) -> map<v, array<V>>;
	identity: <A...>(A...) -> A...;
	includes: <I,V>(t: map<I,V>, needle: V) -> boolean;
	isCallable: (a: any) -> boolean;
	is_callable: (a: any) -> boolean;
	isLowerCase: (a: string) -> boolean;
	is_lower_case: (a: string) -> boolean;
	isUpperCase: (a: string) -> boolean;
	is_upper_case: (a: string) -> boolean;
	iterable: <I,V>(a: map<I,V>) -> () -> (I,V);
	iterator: <I, V>(a: iterable<I, V>) -> iterator_function<I, V>;
	join: <I,V>(...map<I,V>) -> map<I,V>;
	joinDeep: <I,V>(source: map<I,V>, delta: map<I,V>) -> map<I,V>;
	join_deep: <I,V>(source: map<I,V>, delta: map<I,V>) -> map<I,V>;
	keyBy: <I,V, i>(t: iterable<I,V>, getKey: (V,I) -> i) -> map<i, V>;
	key_by: <I,V, i>(t: iterable<I,V>, getKey: (V,I) -> i) -> map<i, V>;
	keys: <I>(t: iterable<I, any>) -> array<I>;
	last: <A>(t: array<A>, handler: ((A, number) -> true?)?) -> A;
	leftPad: (input: string, length: number, prefix: string?) -> string;
	left_pad: (input: string, length: number, prefix: string?) -> string;
	map: <I, V, v>(t: iterable<I, V>, handler: iterator_handler<V, I, v>) -> map<I, v>;
	mapFirst: <V, v>(t: array<V>, handler: (V, number) -> v?) -> v?;
	map_first: <V, v>(t: array<V>, handler: (V, number) -> v?) -> v?;
	mapLast: <V, v>(t: array<V>, handler: (V, number) -> v?) -> v?;
	map_last: <V, v>(t: array<V>, handler: (V, number) -> v?) -> v?;
	mapOne: <I, V, v>(t: map<I, V>, handler: ((V, I) -> v?)?) -> v?;
	map_one: <I, V, v>(t: map<I, V>, handler: ((V, I) -> v?)?) -> v?;
	noop: () -> ();
	omit: <I,V>(input: map<I,V>, keys: array<V>) -> map<I,V>;
	pick: <I,V>(input: iterable<I,V>, handler: (V,I) -> any?) -> map<I,V>;
	--prettyLines: (object: any, prettyOp: pretty_options?) -> array<string>;
	--pretty_lines: (object: any, prettyOp: pretty_options?) -> array<string>;
	pretty: (object: any, options: pretty_options?) -> string;
	reduce: <A,B>(arr: array<A>, handler: (last: B, current: A, i: number) -> B, init: B) -> B;
	reverse: <A>(t: array<A>) -> array<A>;
	rightPad: (input:string, len: number, suffix: string?) -> string;
	right_pad: (input:string, len: number, suffix: string?) -> string;
	shallowEqual: (left: any, right: any) -> boolean;
	shallow_equal: (left: any, right: any) -> boolean;
	slice: <A>(t: array<A>, left: number, right: number) -> array<A>;
	some: <I,V>(t: map<I,V>, handler: (V,I)->any?) -> boolean;
	splitOn: (from: string, patt: string) -> array<string>;
	split_on: (from: string, patt: string) -> array<string>;
	startsWith: (from: string, prefix: string) -> boolean;
	starts_with: (from: string, prefix: string) -> boolean;
	trim: (input: string) -> string;
	values: <V>(t: iterable<any,V>) -> array<V>;
	
	-- additional functions not from DashSingular
	all: <I, V>(input: map<I, V>, handler: iterator_handler<V, I, any?>?)-> boolean;
	chain: <T>(...()->T)->()->T?;
	count: <I, V>(input: map<I, V>, handler: iterator_handler<V, I, any?>?)-> number;
	frequencies: <I, V, v>(input: map<I, V>, handler: iterator_handler<V, I, v>?)-> map<v | V, number>;
	max: <I, V, v>(input: map<I, V>, handler: iterator_handler<V, I, v>?, comparator: (a: v, b: v) -> boolean?) -> V;
	min: <I, V, v>(input: map<I, V>, handler: iterator_handler<V, I, v>?, comparator: (a: v, b: v) -> boolean?) -> V;
	sum: <T>(input: array<T>, handler: (T, number) -> number?) -> number;
	zip: <T, U>(array<T>, array<U>) -> () -> (T, U);
}

--// MAIN
local module = {}
local is_client = game:GetService('RunService'):IsClient()

module.asset_id = 15239197565

module.library_index_presence = {
	all         = true; append       = true; assertEqual = true; assign   = true; chain       = true; class      = true;
	collect     = true; collectArray = true; collectSet  = true; compose  = true; copy        = true; count      = true;
	cycles      = true; endsWith     = true; Error       = true; filter   = true; find        = true; findIndex  = true;
	flat        = true; forEach      = true; forEachArgs = true; format   = true; formatValue = true; freeze     = true;
	frequencies = true; getOrSet     = true; groupBy     = true; identity = true; includes    = true; isCallable = true;
	isLowercase = true; isUppercase  = true; iterable    = true; iterator = true; join        = true; joinDeep   = true;
	keyBy       = true; keys         = true; last        = true; leftPad  = true; map         = true; mapFirst   = true;
	mapLast     = true; mapOne       = true; max         = true; min      = true; None        = true; noop       = true;
	omit        = true; pick         = true; pretty      = true; product  = true; reduce      = true; reverse    = true;
	rightPad    = true; shallowEqual = true; slice       = true; some     = true; splitOn     = true; startsWith = true;
	sum         = true; Symbol       = true; trim        = true; Types    = true; values      = true; zip        = true;
}

module.library_index_add = {
	assert_equal  = 'assertEqual' ; collect_array = 'collectArray'; collect_set   = 'collectSet' ; ends_with    = 'endsWith'   ;
	find_index    = 'findIndex'   ; for_each      = 'forEach'     ; for_each_args = 'forEachArgs'; get_or_set   = 'getOrSet'   ;
	group_by      = 'groupBy'     ; is_callable   = 'isCallable'  ; is_lowercase  = 'isLowercase'; is_uppercase = 'isUppercase';
	join_deep     = 'joinDeep'    ; key_by        = 'keyBy'       ; left_pad      = 'leftPad'    ; map_first    = 'mapFirst'   ;
	map_last      = 'mapLast'     ; map_one       = 'mapOne'      ; none          = 'None'       ; right_pad    = 'rightPad'   ;
	shallow_equal = 'shallowEqual'; split_on      = 'splitOn'     ; starts_with   = 'startsWith' ;
}

local present_module_script_check = script.Parent:FindFirstChild('Dash')

if present_module_script_check then
	module.module_script = Promise.resolve(present_module_script_check)
elseif not is_client then
	module.module_script = AssetService.load_asset(module.asset_id)
		:upon(LuaULibs.middle.get_module_script)
		:tap(LuaULibs.middle.move_to_repo)
else
	module.module_script = Promise.try(LuaULibs.middle.repo_await, 'Dash')
		:tap(function(module_script)
			local promises = {}
			
			for i in module.library_index_presence do
				table.insert(promises, Promise.try(LuaULibs.middle.await_child, module_script, i))
			end
			
			local single_ton = Promise.all(promises)
			
			single_ton:await()
		end)
end

module.promise = module.module_script
	:upon(require)
	:append_args(module, module.library_index_presence)
	:upon(LuaULibs.middle.imprint)
	:append_args(module, module.library_index_add)
	:upon(LuaULibs.middle.imprint)

return module :: typeof(module) & module
