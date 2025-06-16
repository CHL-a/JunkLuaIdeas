module = {}
local Set = require('./@CHL>Set')
local Enums = require('./@CHL>Enum')

export type representives = Enums.default_types<Enum.Material>

module.basepart_usuable_set = Set.simple.from.arrays{256,272,288,512,528,784,788,800,804,816,820,
	832,836,848,864,880,896,912,1040,1056,1072,1088,1280,1284,1296,1312,1328,1344,1360,1376,1392,
	1536,1552,1568,1584,2304,2305,2306,2307,2308,2309,2309,2310,2311}

module.terrain_usable_set = Set.simple.from.arrays{528,788,800,804,816,820,836,848,880,896,912,
	1040,1280,1284,1296,1328,1344,1360,1376,1392,1536,1552,1792,2048}

function module.to_material_enum(value: representives): Enum.Material
	return Enums.default_enum.enumify(value, Enum.Material)
end

function module.is_basepart_usable(value: representives)
	return module.basepart_usuable_set[module.to_material_enum(value).Value]
end

function module.is_terrain_usable(value: representives)
	return module.terrain_usable_set[module.to_material_enum(value).Value]
end

return module
