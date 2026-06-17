local module = {}
local Dash = require('./@roblox>Dash')

module.__index = module

--#####################################################################################
--#####################################################################################
--#####################################################################################
export type simple<I,V> = Dash.map<I, V>

simple = {}

function flip_array<A>(a: {A}): simple<A, number>
	return Dash.collect(a, function(a0: number, a1)return a1, a0  end)
end

module.simple = simple
module.simple.flipArray = flip_array

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type dictionary<T> = simple<string, T>


return module
