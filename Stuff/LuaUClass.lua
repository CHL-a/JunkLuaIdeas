export type subclass<super> = super & {
	__super: super;
}

local Class = {}

function inherit<A>(t: A): subclass<A>
	local a = t
	local result = table.clone(a)
	result.__super = t;
	
	return result
end

Class.inherit = inherit

return Class