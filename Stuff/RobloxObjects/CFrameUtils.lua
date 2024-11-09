local module = {}

module.from = {}

--[[
	Returns CFrame from degrees x,y,z
]]
function module.from.degrees_orientation(x: number, y: number, z: number): CFrame
	return CFrame.fromOrientation(math.rad(x), math.rad(y), math.rad(z))
end

function module.from.degrees_vector(o :Vector3): CFrame
	return module.from.degrees_orientation(o.X, o.Y, o.Z)
end

function module.from.roblox_pack_1(p: {number}, o: {number}): CFrame
	return CFrame.new(unpack(p)) *
		module.from.degrees_orientation(unpack(o))
end

return module
