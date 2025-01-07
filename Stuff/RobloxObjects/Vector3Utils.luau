local module = {}

local Objects = script.Parent
local Dash = require(Objects["@CHL/DashSingular"])
local Math = require(Objects["@CHL/Math"])

round = Math.round
pi = math.pi

function getRelativeVector(cf: CFrame, world: Vector3): Vector3
	return cf.RightVector * world.X + 
		cf.UpVector * world.Y + 
		cf.LookVector * world.Z
end

export type worldPositionObject = BasePart | Attachment

function getAbsolutePosition(v: worldPositionObject): Vector3
	if typeof(v) == 'Instance' then
		if v:IsA('BasePart') then
			return v.Position
		elseif v:IsA('Attachment') then
			return v.WorldPosition
		else
			error(`Unknown v {v} of class {v.ClassName} `)
		end
	else
		error(`Unknown type v of {v} of type {typeof(v)}`)
	end
end

function components(v3: Vector3)return v3.X, v3.Y, v3.Z end

--[[
	This function needs a comment to clarify what it returns.
	
	In order, this function returns:
		The magnitude (number)
		The yaw (World space, number, degrees, [-180, 180])
		The pitch (World space, number, degrees, [-90, 90])
	
	Yaw and pitch adjusted based on part orientation tests.
]]
function getSphereCoordinates(v3: Vector3)
	local mag = v3.Magnitude
	local x, y, z = components(v3)
	local flat = (x * x + z * z) ^ .5

	local yaw = math.atan2(-z, x) * 180 / pi
	local pitch = math.atan(y / flat) * 180 / pi

	return mag, yaw, pitch
end

function getCloserVector3(x: Vector3, other: Vector3, ...: Vector3): Vector3
	local result = other
	local small = (x - other).Magnitude
	
	Dash.forEachArgs(function(a)
		local aSmall = (x - a).Magnitude
		
		if aSmall < small then
			small = aSmall
			result = a
		end
	end, ...)
	
	return result
end

function clamp(x: Vector3, min: Vector3, max: Vector3): Vector3
	return Vector3.min(max, Vector3.max(x, min))
end

function between_magnitude_sum(a: {Vector3}): number 
	local result = 0
	
	for i = 2, #a do
		result += (a[i-1]-a[i]).Magnitude
	end
	
	return result
end

function to_string(a: Vector3, digits: number?): string
	local d = digits or 3
	return `{round(a.X,d)},{round(a.Y,d)},{round(a.Z,d)}`
end

module.between_magnitude_sum = between_magnitude_sum;
module.getRelativeVector = getRelativeVector
module.getAbsolutePosition = getAbsolutePosition
module.getSphereCoordinates = getSphereCoordinates
module.components = components
module.getCloserVector3 = getCloserVector3
module.clamp = clamp

return module
