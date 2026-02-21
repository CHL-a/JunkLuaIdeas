--// TYPES
local Dash = require('./@CHL>DashSingular')
local LuaUTypes = require('./LuaUTypes')

export type simple<I> = Dash.Set<I>
export type array_set<V> = {V}

--// MAIN

disguise = LuaUTypes.disguise
per_arg = Dash.forEachArgs
compose = Dash.compose
forEach = Dash.forEach

local module = {}

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

simple = {}

function simple.is_empty<A>(s: simple<A>): boolean return next(s) == nil end
function simple.get_size<A>(s: simple<A>): number local count = 0 for _ in s do count += 1 end return count end

function simple.to_array<A>(s: simple<A>): {A}
	local result = {}

	for i in s do
		table.insert(result, i)
	end

	return result
end

module.simple = simple

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

imprint = {}

function imprint.args<A>(onto: simple<A>, ...: A): simple<A> per_arg(function(a)onto[a] = true;end, ...) return onto end
function imprint.chars<A>(onto: simple<A>, chars: string): simple<A>for i = 1, #chars do onto[chars:sub(i, i)] = true end return onto end

function imprint.arrays<A>(onto: simple<A>, first: {A}, ...: {A}): simple<A>
	per_arg(function(a)forEach(a, function(v)onto[v] = true;end)end, first, ...)
	return onto
end

function imprint.strings<A>(onto: simple<A | string>, input_string: string, separator: (string | ',')?): simple<A | string>
	local sep = separator or ','
	
	return imprint.arrays(onto, input_string:split(sep))
end

function imprint.sets<A>(onto: simple<A>, ...: simple<A>): simple<A>
	per_arg(function(set)
		for i in set do 
			onto[i] = true 
		end 
	end, ...)
	return onto
end

function imprint.char_ranges<A>(onto: simple<A | string>, ...: string): simple<A | string>
	per_arg(function(range: string)
		local start_at = range:byte(1)
		local end_at = range:byte(2)
		
		for i = start_at, end_at do
			onto[string.char(i)] = true
		end
	end, ...)
end

simple.imprint = imprint

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

simple.from = {}

function __from_compose1(...)return {}, ...end

simple.from.args = compose(__from_compose1, imprint.args) :: <A>(a: A, ...A) -> simple<A>;
simple.from.chars = compose(__from_compose1, imprint.chars) :: (string) -> simple<string>;
simple.from.arrays = compose(__from_compose1, imprint.arrays) :: <A>(first: {A}, ...{A}) -> simple<A>;
simple.from.strings = compose(__from_compose1, imprint.strings) :: <A>(input_string: string, separator: (string | ',')?) -> simple<A | string>;
simple.from.sets = compose(__from_compose1, imprint.sets) :: <A>(...simple<A>) -> simple<A>;
simple.from.char_ranges = compose(__from_compose1, imprint.char_ranges) :: <A>(...string) -> simple<A | string>;

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

operations = {}

function operations.union<A>(onto: simple<A>?, set_a: simple<A>, set_b: simple<A>): simple<A>
	local result = onto or {}
	
	for k in set_a do
		result[k] = true
	end
	
	for k in set_b do
		result[k] = true
	end
	
	return result
end

function operations.intersection<A>(onto: simple<A>?, set_a: simple<A>, set_b: simple<A>): simple<A>
	local result = onto or {}
	
	for k in set_a do
		if set_b[k] then
			result[k] = true
		else
			result[k] = nil
		end
	end
	
	return result
end

function operations.difference<A>(onto: simple<A>?, set_a: simple<A>, set_b: simple<A>): simple<A>
	local result = onto or {}
	
	for k in set_a do
		if not set_b[k] then
			result[k] = true
		else
			result[k] = nil
		end
	end
	
	return result
end

simple.operations = operations

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

array_set = {}

function array_set.has<A>(set: array_set<A>, item: A): boolean return not not array_set.get_location(set, item)end
function array_set.get_location<A>(set: array_set<A>, item: A): number? return table.find(set, item) end

function array_set.add<A>(set: array_set<A>, ...: A): ()
	local n = select('#', ...)

	for i = 1, n do
		local v = select(i, ...)

		if array_set.get_location(set, v) then continue end

		table.insert(set, v)
	end
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

module.array_set = array_set

return module
