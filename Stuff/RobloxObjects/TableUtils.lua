local module = {}
local LuaUTypes = require(script.Parent.LuaUTypes)
local disguise = LuaUTypes.disguise

function module.deepSoftIndex<A, B>(t: {[A]: any}, ...: A): B?
	for i = 1, select('#', ...) do
		local index = select(i, ...)
		t = t[index]
		
		if not t then return end
	end
	
	return disguise(t);
end

function module.safeSet(t: any, i: any, v: any): (boolean, string?)
	return pcall(function()
		t[i] = v
	end)
end

function module.imprint<A>(t: A, t2: {[any]: any}, shouldWarn: boolean?): A
	for i, v in next, t2 do
		local s, e = module.safeSet(t, i, v)
		if shouldWarn and s then
			warn(e)
		end
	end
	
	return t
end

function module.push<A, B>(t: A, ...: B): A
	for i = 1, select('#', ...) do
		local a = select(i, ...)
		table.insert(disguise(t), a)
	end
	return t
end

function module.clearNils<A>(t: A): A
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

return module
