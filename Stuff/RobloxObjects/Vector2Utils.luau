local module = {}

local Math = require(script.Parent["@CHL/Math"])

round = Math.round

function module.to_string(a: Vector2, digits: number?): string
	local d = digits or 3
	return `{round(a.X,d)},{round(a.Y,d)}`
end

return module
