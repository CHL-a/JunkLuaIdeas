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

export type executor = (resolve: any_func, reject: any_func, on_cancel: (abortHandler: any_func?) -> boolean) -> ()

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
	defer: (executor)->object<...any>;
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
	new: (executor: executor) -> object<...any>;
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

function module.get(): module
	return require('./@evaera>Promise')
end

--#######################################################################################
--#######################################################################################
--#######################################################################################

export type modified_object<T...> = {
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
} & object<T...>

export type modified_module = {
	all_settled: (promises: {modified_object<...any>})->object<{status}>;
	from_event: <T...>(event: event, predicate: (T...) -> boolean?) -> modified_object<T...>;
	on_unhandled_rejection: (callback: (promise: modified_object<...any>, error: any) -> ()) -> ();
	retry_with_delay: <P, T>(executor: (...P)->modified_object<T>, seconds: number ,times: number) -> modified_object<T>;
}

disguise = require('./LuaUTypes').disguise

module.modified = {}

module.modified.object_states = {
	andThen = 'and_then';
	andThenCall = 'and_then_call';
	andThenReturn = 'and_then_return';
	awaitStatus = 'await_status';
	finallyCall = 'finally_call';
	finallyReturn = 'finally_return';
	getStatus = 'get_status';
}

module.modified.module_states = {
	allSettled = 'all_settled';
	fromEvent = 'from_event';
	onUnhandledRejection = 'on_unhandled_rejection';
	retryWithDelay = 'retry_with_delay';
}

function module.modified.get(): modified_module
	local result = disguise(module.get())
	
	local proto = result.prototype
	
	for i, v in module.modified.object_states do
		proto[v] = proto[i]
	end
	
	for i, v  in module.modified.module_states do
		result[v] = result[i]
	end
	
	return result
end

return module
