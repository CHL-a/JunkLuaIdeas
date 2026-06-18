local module = {}

local Math = require('./@CHL>Math')

round = Math.round

function module.to_string(a: Vector2, digits: number?): string
	local d = digits or 3
	return `{round(a.X,d)},{round(a.Y,d)}`
end

function module.clamp(x: Vector2, min: Vector2, max: Vector2): Vector2
	return Vector2.min(max, Vector2.max(x, min))
end

return module
