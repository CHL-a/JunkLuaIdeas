local module = {}
local LuaUTypes = require(script.Parent.LuaUTypes)
local disguise = LuaUTypes.disguise



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

	while i > #b do
		if b[i] == nil then
			table.remove(b,i)
			i -= 1
		end
		i += 1
	end

	return t
end

function fill<A>(ground: A, concrete: A): A
	local a, b = disguise(ground, concrete)
	
	for i, v in next, b do
		if a[i] == nil then
			a[i] = v
		end
	end
	
	return ground
end

function defaultify<A>(a: A?, default: A): A
	if not a then return default end
	
	fill(a, default)
	
	return a
end

module.deepSoftIndex = deepSoftIndex
module.safeSet = safeSet
module.imprint = imprint
module.push = push
module.clearNils = clearNils
module.fill = fill

return module
