local module = {}

module.isNan = function(x: number)return x ~= x end

module.isInfinity = function(x:number)return x+1==x;end

return module
