local module = {}

module.getRelativeVector = function(cf: CFrame, world: Vector3)
	return cf.RightVector * world.X + 
		cf.UpVector * world.Y + 
		cf.LookVector * world.Z
end

return module
