--[[
	from https://eryn.io/roblox-lua-promise/api/Promise#catch
	
	will resolve all types sometime
]]

export type status = 'Started' | 'Resolved' | 'Rejected' | 'Cancelled'

export type func<Params..., Returns...> = (Params...)->(Returns...)
export type any_func = func<...any, ...any>

export type object<T...> = {
	Status: status;
	
	andThen: (self: object<T...>, on_success: any_func, on_fail: any_func?)->object<T...>;
	andThenCall: (self: object<T...>, callback: any_func, ...any)->object<T...>;
	andThenReturn: (self: object<T...>, ...any)->object<T...>;
	await: (self: object<T...>) -> (boolean, T...);
	awaitStatus: (self: object<T...>) -> (status, T...);
	cancel: (self: object<T...>) -> ();
	catch: (self: object<T...>, on_reject: any_func) -> object<T...>;
	expect: (self: object<T...>) -> (T...);
	finally: (self: object<T...>, on_resolve: any_func) -> object<T...>;
	finallyCall: (self: object<T...>, callback: any_func, ...any)->object<T...>;
	finallyReturn: (self: object<T...>, ...any)->object<T...>;
	getStatus: (self: object<T...>)->Status;
	now: (self: object<T...>, rejection_value: any?) -> object<T...>;
	tap: (self: object<T...>, tap_callback: any_func) -> object<T...>;
	timeout: (self: object<T...>, seconds: number, rejection_value: any?) -> object<T...>;
}

export type executor<T...> = <U...>(resolve: (T...)->(), reject: (U...)->(), on_cancel: (abortHandler: any_func?) -> boolean) -> ()

export type event = {
	Connect: any_func;
}

export type module = {
	Status: {
		Started: 'Started';
		Resolved: 'Resolved';
		Rejected: 'Rejected';
		Cancelled: 'Cancelled';
	};

	all: (promises: {object<...any>}) -> object<...any>;
	allSettled: (promises: {object<...any>}) -> object<{status}>;
	any: (promises: {object<...any>}) -> object<...any>;
	defer: <T...>(executor<T...>)->object<...any>;
	delay: (seconds: number) -> object<...any>;
	each: <T, U>(
		list: {T | object<T>},
		predicate: (value: T, index: number) -> U | object<U>
	) -> object<{U}>;
	fold: <T, U>(
		list: {T | object<T>},
		reducer: (accumulator: U, value: T, index: number) -> U | object<U>,
		init: U
	) -> ();
	fromEvent: <T...>(event: event, predicate: (T...) -> boolean?) -> object<T...>;
	is: (any)->boolean;
	new: <T...>(executor: executor<T...>) -> object<...any>;
	onUnhandledRejection: (event: (promise: object<...any>, error: any) -> ()) -> ();
	promisify: <T...>(callback: (T...) -> ()) -> (T...) -> object<...any>;
	race: <T>(promises: {object<T>}) -> object<T>;
	reject: (...any) -> object<...any>;
	resolve: (...any) -> object<...any>;
	retry: <P, T>(executor: (...P)->object<T>, times: number) -> object<T>;
	retryWithDelay: <P, T>(executor: (...P)->object<T>, seconds: number ,times: number) -> object<T>;
	some: <T>(promises: {object<T>}, count: number) -> object<{T}>;
	try: <T...>(callback: (T...) -> (), T...) -> object<...any>;
}

module = {}

local disguise = require('./LuaUTypes').disguise

function module.get(): module return disguise(require)('./@evaera>Promise') end

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

export type modified_object<T...> = {
	-- inherited calls, reflected to return modified_object
	andThen: (self: modified_object<T...>, on_success: any_func, on_fail: any_func?)->modified_object<T...>;
	andThenCall: (self: modified_object<T...>, callback: any_func, ...any)->object<T...>;
	andThenReturn: (self: modified_object<T...>, ...any)->object<T...>;
	await: (self: modified_object<T...>) -> (boolean, T...);
	awaitStatus: (self: modified_object<T...>) -> (status, T...);
	cancel: (self: modified_object<T...>) -> ();
	catch: (self: modified_object<T...>, on_reject: any_func) -> modified_object<T...>;
	expect: (self: modified_object<T...>) -> (T...);
	finally: (self: modified_object<T...>, on_resolve: any_func) -> modified_object<T...>;
	finallyCall: (self: modified_object<T...>, callback: any_func, ...any)->object<T...>;
	finallyReturn: (self: modified_object<T...>, ...any)->object<T...>;
	getStatus: (self: modified_object<T...>)->Status;
	now: (self: modified_object<T...>, rejection_value: any?) -> modified_object<T...>;
	tap: (self: modified_object<T...>, tap_callback: any_func) -> modified_object<T...>;
	timeout: (self: modified_object<T...>, seconds: number, rejection_value: any?) -> modified_object<T...>;
	
	and_then: (self: modified_object<T...>, on_success: any_func, on_fail: any_func?)->modified_object<T...>;
	and_then_call: (self: modified_object<T...>, callback: any_func, ...any)->modified_object<T...>;
	and_then_return: (self: modified_object<T...>, ...any)->modified_object<T...>;
	await_status: (self: modified_object<T...>) -> (status, T...);
	finally_call: (self: modified_object<T...>, callback: any_func, ...any)->modified_object<T...>;
	finally_return: (self: modified_object<T...>, ...any)->modified_object<T...>;
	get_status: (self: modified_object<T...>) -> status;
	
	-- additions
	-- same as and_then
	upon: (self: modified_object<T...>, on_success: any_func, on_fail: any_func?)->modified_object<T...>;
	upon_call: (self: modified_object<T...>, callback: any_func, ...any)->modified_object<T...>;
	upon_return: (self: modified_object<T...>, ...any)->modified_object<T...>;
	
	-- availible functions
	resolve: (self: modified_object<T...>,T...) -> ();
	reject: (self: modified_object<T...>,T...) -> ();
	
	append_args: (self: modified_object<T...>, ...any)->modified_object<T...>;
	
}

export type modified_module = {
	all_settled: (promises: {modified_object<...any>})->object<{status}>;
	from_event: <T...>(event: event, predicate: (T...) -> boolean?) -> modified_object<T...>;
	on_unhandled_rejection: (callback: (promise: modified_object<...any>, error: any) -> ()) -> ();
	retry_with_delay: <P, T>(executor: (...P)->modified_object<T>, seconds: number ,times: number) -> modified_object<T>;
	
	Status: {
		Started: 'Started';
		Resolved: 'Resolved';
		Rejected: 'Rejected';
		Cancelled: 'Cancelled';
	};
	all: <T...>(promises: {modified_object<T...>}) -> modified_object<T...>;
	allSettled: (promises: {modified_object<...any>}) -> modified_object<{status}>;
	any: <T...>(promises: {modified_object<T...>}) -> modified_object<T...>;
	defer: <T...>(executor<T...>)->modified_object<T...>;
	delay: <T...>(seconds: number) -> modified_object<T...>;
	each: <T, U>(
		list: {T | modified_object<T>},
		predicate: (value: T, index: number) -> U | modified_object<U>
	) -> modified_object<{U}>;
	fold: <T, U>(
		list: {T | modified_object<T>},
		reducer: (accumulator: U, value: T, index: number) -> U | modified_object<U>,
		init: U
	) -> ();
	fromEvent: <T...>(event: event, predicate: (T...) -> boolean?) -> modified_object<T...>;
	is: (any)->boolean;
	new: <T...>(executor: executor<T...>) -> modified_object<T...>;
	onUnhandledRejection: (event: (promise: modified_object<...any>, error: any) -> ()) -> ();
	promisify: <T..., U...>(callback: (T...) -> U...) -> (T...) -> modified_object<U...>;
	race: <T>(promises: {modified_object<T>}) -> modified_object<T>;
	reject: <T...>(T...) -> modified_object<T...>;
	resolve: <T...>(T...) -> modified_object<T...>;
	retry: <P..., T...>(executor: (P...)->modified_object<T...>, times: number) -> modified_object<T...>;
	retryWithDelay: <P..., T...>(executor: (P...)->modified_object<T...>, seconds: number ,times: number) -> modified_object<T...>;
	some: <T>(promises: {modified_object<T>}, count: number) -> modified_object<{T}>;
	try: <T..., U...>(callback: (T...) -> U..., T...) -> modified_object<U...>;
}

disguise = require('./LuaUTypes').disguise

module.modified = {}

module.modified.object_states = {
	and_then        = 'andThen';
	and_then_call   = 'andThenCall';
	and_then_return = 'andThenReturn';
	await_status    = 'awaitStatus';
	finally_call    = 'finallyCall';
	finally_return  = 'finallyReturn';
	get_status      = 'getStatus';
	-- additions
	upon            = 'andThen';
	upon_call       = 'andThenCall';
	upon_return     = 'andThenReturn';
	
	resolve         = '_resolve';
	reject          = '_reject';
}

module.modified.module_states = {
	all_settled            = 'allSettled';
	from_event             = 'fromEvent';
	on_unhandled_rejection = 'onUnhandledRejection';
	retry_with_delay       = 'retryWithDelay';
}

--########################################################################################################################################################
--########################################################################################################################################################
--########################################################################################################################################################

function module.implant()
	if module.is_implanted then
		return
	end
	
	local default = module.get()
	
	for i, v in default do
		module[i] = v
	end
	
	local proto = module.prototype
	
	for i, v in module.modified.object_states do
		proto[i] = proto[v]
	end
	
	for i, v in module.modified.module_states do
		module[i] = module[v]
	end
	
	function proto.append_args<T..., U...>(self: modified_object<T...>, ...: U...): modified_object<T...>
		local u_args = { ... }
		return self:upon(function(...)
			local t_args = { ... }
			
			table.move(u_args, 1, #u_args, #t_args + 1, t_args)
			
			return unpack(t_args)
		end)
	end
	
	module.is_implanted = true
end

return module :: typeof(module) & modified_module
