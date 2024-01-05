--[[
	based from: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/
]]

local Iterator = require(script.Parent["@CHL/Iterator"])

type __object<I, V> = {
	getSize: (self: __object<I, V>) -> number;
	
	clear: (self: __object<I, V>) -> nil;
	delete: (self: __object<I, V>, i: I) -> boolean?;
	entries: (self: __object<I, V>) -> Iterator.object<I, V>;
	forEach: (self: __object<I, V>, fn: (v: V, i: I) -> any?) -> nil;
	get: (self: __object<I, V>, i: I) -> V?;
	has: (self: __object<I, V>, i: I) -> boolean;
	keys: (self: __object<I, V>) -> Iterator.object<I>;
	set: (self:__object<I, V>, i: I, v: V) -> nil;
	values: (self: __object<I, V>) -> Iterator.object<V>
}

export type object<I, V> = __object<I, V>

return true
