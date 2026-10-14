--[[
	Possibly used for discerning visual issues among homoglyphs. Uses a type of map-referral-set by reference
]]

local Set = require('./@CHL>Set')
local Map = require('./@CHL>Map')
local module = {}

export type character = string
export type char = character

function module.add_map_set(c: char)
	local set = {[c] = true}
	
	module.map_set_bin[c] = set
	
	return set
end

function module.add_char_to_set(c: char, similar_c: char)
	local c_set = module.map_set_bin[c]
	
	if not c_set then
		c_set = module.add_map_set(c)
	end
	
	module.map_set_bin[similar_c] = c_set
	
	c_set[similar_c] = true
end

--[[
	Specifically includes all ascii homoglyphs
]]
function module.ascii()
	module.add_map_set('0')
	module.add_char_to_set('0', 'O')
	
	module.add_map_set('1')
	module.add_char_to_set('1', 'I')
	module.add_char_to_set('1', 'l')
	
	module.add_map_set('5')
	module.add_char_to_set('5', 'S')
	
	module.add_map_set('8')
	module.add_char_to_set('8', 'B')
	
	module.add_map_set('9')
	module.add_char_to_set('9', 'g')
end

module.map_set_bin = {}

return module
