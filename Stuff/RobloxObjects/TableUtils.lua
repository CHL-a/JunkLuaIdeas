local module = {}
local LuaUTypes = require(script.Parent.LuaUTypes)

disguise = LuaUTypes.disguise

function isEmpty(a: {[any]: any}): boolean return next(a) == nil end

function deepSoftIndex<A, B>(t: {[A]: any}, ...: A): B?
	for i = 1, select('#', ...) do
		local index = select(i, ...)
		t = t[index]

		if not t then return end
	end

	return disguise(t);
end

function safeSet(t: any, i: any, v: any): (boolean, string?)
	return pcall(function()
		t[i] = v
	end)
end

function imprint<A>(t: A, t2: {[any]: any}, shouldWarn: boolean?): A
	for i, v in next, t2 do
		local s, e = safeSet(t, i, v)
		if shouldWarn and not s then
			warn(e)
		end
	end

	return t
end

function push<A, B>(t: A, ...: B): A
	for i = 1, select('#', ...) do
		local a = select(i, ...)
		table.insert(disguise(t), a)
	end
	return t
end

function clearNils<A>(t: A): A
	local i = 1
	local b = disguise(t)

	while i <= #b do
		if b[i] == nil then
			table.remove(b,i)
			i -= 1
		end
		i += 1
	end

	return t
end

function fill<A>(ground: A?, concrete: A): A
	local a, b = disguise(ground, concrete)
	if not a then
		return disguise(table.clone(b))
	end
	
	for i, v in next, b do
		if a[i] == nil then
			a[i] = v
		end
	end
	
	return disguise(ground)
end

function defaultify<A>(a: A?, default: A): A
	return not a and default or fill(a, default)
end

function isProperArray(a: {[any]: any}): boolean
	return type(disguise(next(a))) == 'number' and next(a, #a) == nil
end

--[[do not use cyclic tables]]
function deepClone<A>(t: A): A
	local a = table.clone(disguise(t))
	
	local list = {a}
	
	while #list > 0 do
		local b = table.remove(list, 1)
		
		for i, v in next, b do
			if type(v) == 'table' then
				v = table.clone(v)
				
				table.insert(list, v)
			end
		end
	end
	
	return a
end

function valueSet<I, V>(t: {[I]: V}): {[V]: true}
	local result = {}
	
	for _, v in next, t do 
		result[v] = true
	end
	
	return result
end

function keys<I,V>(t: {[I]:V}):{I}
	local result = {}
	
	for i in next, t do
		table.insert(result, i)
	end
	
	return result
end

function randomValue<I,V>(t: {[I]: V}): V
	local ks = keys(t)
	
	return t[ks[math.random(1, #ks)]]
end

module.deepSoftIndex = deepSoftIndex
module.safeSet = safeSet
module.imprint = imprint
module.push = push
module.clearNils = clearNils
module.fill = fill
module.defaultify = defaultify
module.isProperArray = isProperArray
module.isEmpty = isEmpty
module.deepClone = deepClone
module.valueSet = valueSet
module.keys = keys
module.randomValue = randomValue

return module
