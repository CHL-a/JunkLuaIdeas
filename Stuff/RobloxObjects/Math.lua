module = {}

module.epsilon = 9E-323

function module.isNan(x: number)return x ~= x end
function module.isInfinity(x:number)return x+1==x;end

module.radix = {}

function module.radix.getDigit(n: number, base: number?, i: number)
	return (n // ((base or 10) ^ i)) % (base or 10)
end

function module.radix.digit_length(n: number, base: number?)
	local result = 1

	if n > 0 then
		result += math.log(n, base) // 1
	end

	return result
end

module.factorial = {}

function module.factorial.func(x: number)
	local r = 1
	for i = 1, x do r *= i end
	return r
end

factorial = module.factorial.func

function module.factorial.combination(n: number, k: number)
	return factorial(n) / (factorial(k) * factorial(n - k))
end

module.bezier = {}
module.bezier.factory_funcs = {}

function module.bezier.factory(n: number) : <U>(t: number, now: {U}, zero: U?)-> U
	if module.bezier.factory_funcs[n] then return module.bezier.factory_funcs[n] end
	
	local function func<U>(t: number, now: {U}, zero: U?) : U
		assert(#now == n + 1)
		local r = zero or 0
		for i = 0, n do
			local fact = module.factorial.combination(n, i)
			local a = (1 - t) ^ (n - i)
			local b = t ^ i
			
			r += fact 
				* a
				* b
				* now[i + 1]
		end
		
		return r
	end
	
	module.bezier.factory_funcs[n] = func
	
	return func
end

return module
