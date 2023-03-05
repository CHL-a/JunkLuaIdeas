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
	
	if methods then
		if mt then
			mt = table.clone(mt)

			local cloneIndex = mt.__index and table.clone(mt.__index) or {}

			mt.__index = cloneIndex

			for i, v in next, methods do
				cloneIndex[i] = v
			end
		end
		
		setmetatable(result, mt or methods)
	end
	
	if mt and methods then
		
	end
	
	if methods then
	end
	
	return result
end

Class.inherit = inherit

return Class
