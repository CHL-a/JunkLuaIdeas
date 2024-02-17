module = {}

function isNan(x: number)return x ~= x end
function isInfinity(x:number)return x+1==x;end
function oneDLerp(i: number, f:number, a: number)return i + (f - i) * a end

function getDigit(n: number, base: number?, i: number)
	return (n // ((base or 10) ^ i)) % (base or 10)
end

function getDigits(n: number, base: number?)
	local result = 1

	if n > 0 then
		result += math.log(n, base) // 1
	end

	return result
end

module.epsilon = 9E-323
module.isNan = isNan
module.isInfinity = isInfinity
module.oneDLerp = oneDLerp
module.getDigit = getDigit
module.getDigits = getDigits

return module
