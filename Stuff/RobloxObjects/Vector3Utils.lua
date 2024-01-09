local module = {}

module.getRelativeVector = function(cf: CFrame, world: Vector3)
	return cf.RightVector * world.X + 
		cf.UpVector * world.Y + 
		cf.LookVector * world.Z
end

type __worldPositionObject = BasePart | Attachment
export type worldPositionObject = __worldPositionObject

module.getAbsolutePosition = function(v: __worldPositionObject): Vector3
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

return module
