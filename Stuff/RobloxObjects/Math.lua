local module = {}

module.epsilon = 9E-323

module.isNan = function(x: number)return x ~= x end
module.isInfinity = function(x:number)return x+1==x;end
module.oneDLerp = function(i: number, f:number, a: number)return i + (f - i) * a end

return module
