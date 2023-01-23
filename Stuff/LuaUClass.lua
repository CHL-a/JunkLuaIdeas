export type subclass<super> = super & {
	__super: super;
}

local Class = {}

function inherit<A>(t: A, methods): subclass<A>
	local a = t
	local result = table.clone(a)
	result.__super = t;
	
	-- metatable evaluation
	local mt = getmetatable(result)
	
	if mt and methods then
		mt = table.clone(mt)
		
		local cloneIndex = table.clone(mt.__index)
		
		mt.__index = cloneIndex
		
		for i, v in next, methods do
			cloneIndex[i] = v
		end
		
		setmetatable(result, mt)
	end
	
	return result
end

Class.inherit = inherit

return Class
