local module = {}

local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>

function module.pick_array_element<V>(random: Random, array: {V}): V
	local n = #array
	
	return array[random:NextInteger(1, n)]
end

module.default_lib = Random

return module
