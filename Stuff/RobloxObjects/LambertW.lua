type __module = (x: number, its: number) -> number;
export type module = __module;

function W_iteration(x, g)
	-- an iteration of W function
	local a = math.exp(g)
	local b = g * a

	return g - (b - x) / (a + b)
end

function W(x, its)
	its = its or 7
	local g = x * 0

	for i = 1, its do
		g = W_iteration(x, g)
	end

	return g
end

return W :: __module
