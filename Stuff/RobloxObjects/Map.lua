local Objects = script.Parent
local module = {}
local Dash = require(Objects["@CHL/DashSingular"])
module.__index = module

--#####################################################################################
--#####################################################################################
--#####################################################################################
export type simple<I,V> = Dash.Map<I, V>

simple = {}

function flipArray<A>(a: {A}): simple<A, number>
	return Dash.collect(a, function(a0: number, a1)return a1, a0  end)
end

module.simple = simple
module.simple.flipArray = flipArray

return module
