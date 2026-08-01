local module = {}

local Map = require('./@CHL>Map')

type map<I,V> = Map.simple<I,V>

function module.pick_array_element<V>(array: {V}, random: Random?): V
	local n = #array
	random = random or module.default_random
	
	return array[random:NextInteger(1, n)]
end

module.default_lib = Random
module.default_random = Random.new()

return module
