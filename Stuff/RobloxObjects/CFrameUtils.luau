local module = {}

local Vector3Utils = require('./@CHL>Vector3Utils')
from = {}
flip_v3 = Vector3Utils.flip

--[[
	Returns CFrame from degrees x,y,z
]]
function from.degrees_orientation(x: number, y: number, z: number): CFrame
	return CFrame.fromOrientation(math.rad(x), math.rad(y), math.rad(z))
end

function from.degrees_vector(o :Vector3): CFrame
	return from.degrees_orientation(o.X, o.Y, o.Z)
end

function from.roblox_pack_1(p: {number}, o: {number}): CFrame
	return CFrame.new(unpack(p)) *
		from.degrees_orientation(unpack(o))
end

function flip(cf: CFrame, normal: Vector3)
	local position = flip_v3(cf.Position, normal)
	local look = flip_v3(cf.LookVector, normal)
	local up = flip_v3(cf.UpVector, normal)

	return CFrame.lookAlong(position, look, up)
end
module.from = from

return module
