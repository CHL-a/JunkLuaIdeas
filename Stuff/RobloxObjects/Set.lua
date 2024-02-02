--// TYPES
local Dash = require(script.Parent["@CHL/DashSingular"])

export type simpleSet<I> = Dash.Set<I>

--// MAIN
local module = {}

perArg = Dash.forEachArgs

module.__index = module
module.simple = {}

function module.simple.fromArgs<A>(...: A): simpleSet<A>
	local self = {}
	
	perArg(function(a)self[a] = true;end, ...)
	
	return self
end

function module.simple.fromArrays<A>(a: {A}, ...: {A}): simpleSet<A>
	local self = {}
	
	perArg(function(a)Dash.forEach(a, function(v)self[v] = true;end)end, a, ...)
	
	return self
end


return module
