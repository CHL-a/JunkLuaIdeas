--[[
	based from: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/
]]

local Iterator = require('./@CHL>Iterator')

type iterator<A_first, A...> = Iterator.object<A_first, A...>

export type object<I, V> = {
	getSize: (self: object<I, V>) -> number;

	clear: (self: object<I, V>) -> ();
	delete: (self: object<I, V>, i: I) -> boolean?;
	entries: (self: object<I, V>) -> iterator<I, V>;
	forEach: (self: object<I, V>, fn: (v: V, i: I) -> any?) -> ();
	get: (self: object<I, V>, i: I) -> V?;
	has: (self: object<I, V>, i: I) -> boolean;
	keys: (self: object<I, V>) -> iterator<I>;
	set: (self:object<I, V>, i: I, v: V) -> ();
	values: (self: object<I, V>) -> iterator<V>
}

return true
