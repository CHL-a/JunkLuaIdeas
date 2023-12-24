local module = {}
local LuaUTypes = require(script.Parent.LuaUTypes)
local disguise = LuaUTypes.disguise

function module.deepSoftIndex<A, B>(t: {[A]: any}, ...: A): B?
	for i = 1, select('#', ...) do
		local index = select(i, ...)
		t = t[index]
		
		if not t then return t end
	end
	
	return disguise(t);
end

function module.safeSet(t: any, i: any, v: any)
	return pcall(function()
		t[i] = v
	end)
end

function module.imprint(t: any, t2: {[any]: any}, shouldWarn: boolean?)
	for i, v in next, t2 do
		local s, e = module.safeSet(t, i, v)
		if shouldWarn and s then
			warn(e)
		end
	end
end

return module
