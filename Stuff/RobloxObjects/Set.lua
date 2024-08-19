--// TYPES
local Dash = require(script.Parent["@CHL/DashSingular"])
local LuaUTypes = require(script.Parent.LuaUTypes)

export type simple<I> = Dash.Set<I>
export type array_set<V> = {V}

--// MAIN
simple = {}
array_set = {}

disguise = LuaUTypes.disguise
perArg = Dash.forEachArgs
compose = Dash.compose
forEach = Dash.forEach

function imprintWithArgs<A>(self: simple<A>, ...: A): simple<A>
	perArg(function(a)self[a] = true;end, ...)

	return self
end

function imprintWithArrays<A>(self: simple<A>, a: {A}, ...: {A}): simple<A>
	perArg(function(a)forEach(a, function(v)self[v] = true;end)end, a, ...)

	return self
end

function imprintWithChars<A>(self: simple<A | string>, a: string): simple<A | string>
	for i = 1, #a do
		local c = a:sub(i, i)
		self[c] = true
	end

	return self
end

function imprintWithStrings<A>(
	self:simple<A | string>, 
	a: string, 
	sep: (string | ',')?) : simple<A | string>
	local sepa = sep or ','

	return imprintWithArrays(self, a:split(sepa))
end

function imprintWithSets<A>(self: simple<A>, ...: simple<A>)
	perArg(function(a)
		forEach(a, function(_, a1: A)
			self[a1] = true
		end)
	end, ...)

	return self
end

function imprintWithCharRanges<A>(self: simple<A | string>,
	...: string): simple<A | string>
	perArg(function(a: string)
		local c1 = a:byte(1)
		local c2 = a:byte(2)

		for i = c1, c2 do
			self[string.char(i)] = true
		end
	end, ...)

	return self
end

function __from_compose1(...)return {}, ...end

function __from_index(self, i: string)
	local f = assert(simple.imprint[i], `attempting to access an unavailible method: {i}`)
	local g = compose(__from_compose1, f)

	rawset(self, i, g)
	return g
end

__fromListener = setmetatable({}, {__index = __from_index})

function toArray<A>(s: simple<A>): {A}
	local result = {}

	for i in next, s do
		table.insert(result, i)
	end

	return result
end

--########################################################################################
--########################################################################################
--########################################################################################

function array_set.add<A>(set: array_set<A>, ...: A): ()
	local n = select('#', ...)
	
	for i = 1, n do
		local v = select(i, ...)

		if array_set.get_location(set, v) then continue end

		table.insert(set, v)
	end
end

function array_set.has<A>(set: array_set<A>, item: A): boolean
	return not not array_set.get_location(set, item)
end

function array_set.get_location<A>(set: array_set<A>, item: A): number?
	return table.find(set, item)
end

function array_set.safe_remove<A>(set: array_set<A>, ...: A): ()
	local n = select('#', ...)

	for i = 1, n do
		local v = select(i, ...)

		local i = array_set.get_location(set, v)

		if not i then continue end
		
		table.remove(set, i)
	end
end

--########################################################################################
--########################################################################################
--########################################################################################

export type module = {
	simple: {
		imprint: {
			args: typeof(imprintWithArgs);
			arrays: typeof(imprintWithArrays);
			chars: typeof(imprintWithChars);
			strings: typeof(imprintWithStrings);
			sets: typeof(imprintWithSets);
			charRanges: typeof(imprintWithCharRanges);
		};
		from: {
			args: <A>(a: A, ...A) -> simple<A>;
			arrays: <A>(a: {A}, ...{A}) -> simple<A>;
			chars: <A>(a: string) -> simple<A | string>;
			strings: <A>(a: string, sep: string?) -> simple<A | string>;
			sets: <A>(a: simple<A>, ...simple<A>) -> simple<A>;
			charRanges: <A>(...string) -> simple<A | string>
		};
		toArray: typeof(toArray);
	};
	array_set: typeof(array_set);
}
local module = {} :: module

module.__index = module
module.simple = simple
module.array_set = array_set

imprint = {}
imprint.args = imprintWithArgs
imprint.arrays = imprintWithArrays
imprint.chars = imprintWithChars
imprint.strings = imprintWithStrings
imprint.sets = imprintWithSets
imprint.charRanges = imprintWithCharRanges

simple.imprint = imprint
simple.from = __fromListener
simple.toArray = toArray

return module :: module
