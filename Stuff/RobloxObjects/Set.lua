--// TYPES
local Dash = require(script.Parent["@CHL/DashSingular"])
local LuaUTypes = require(script.Parent.LuaUTypes)

export type simpleSet<I> = Dash.Set<I>

--// MAIN
simple = {}

disguise = LuaUTypes.disguise
perArg = Dash.forEachArgs
compose = Dash.compose
forEach = Dash.forEach

function imprintWithArgs<A>(self: simpleSet<A>, ...: A): simpleSet<A>
	perArg(function(a)self[a] = true;end, ...)

	return self
end

function imprintWithArrays<A>(self: simpleSet<A>, a: {A}, ...: {A}): simpleSet<A>
	perArg(function(a)forEach(a, function(v)self[v] = true;end)end, a, ...)

	return self
end

function imprintWithChars<A>(self: simpleSet<A | string>, a: string): simpleSet<A | string>
	for i = 1, #a do
		local c = a:sub(i, i)
		self[c] = true
	end

	return self
end

function imprintWithStrings<A>(
	self:simpleSet<A | string>, 
	a: string, 
	sep: (string | ',')?) : simpleSet<A | string>
	local sepa = sep or ','
	
	return imprintWithArrays(self, a:split(sepa))
end

function imprintWithSets<A>(self: simpleSet<A>, ...: simpleSet<A>)
	perArg(function(a)
		forEach(a, function(_, a1: A)
			self[a1] = true
		end)
	end, ...)
	
	return self
end

function imprintWithCharRanges<A>(self: simpleSet<A | string>,
	...: string): simpleSet<A | string>
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
			args: <A>(a: A, ...A) -> simpleSet<A>;
			arrays: <A>(a: {A}, ...{A}) -> simpleSet<A>;
			chars: <A>(a: string) -> simpleSet<A | string>;
			strings: <A>(a: string, sep: string?) -> simpleSet<A | string>;
			sets: <A>(a: simpleSet<A>, ...simpleSet<A>) -> simpleSet<A>;
			charRanges: <A>(...string) -> simpleSet<A | string>
		}
	}
}
local module = {} :: module

module.__index = module

module.simple = simple

imprint = {}
imprint.args = imprintWithArgs
imprint.arrays = imprintWithArrays
imprint.chars = imprintWithChars
imprint.strings = imprintWithStrings
imprint.sets = imprintWithSets
imprint.charRanges = imprintWithCharRanges
simple.imprint = imprint

simple.from = __fromListener

return module :: module
