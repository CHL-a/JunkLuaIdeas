local module = {}

-- r_string
readu32 = buffer.readu32
readu8  = buffer.readu8
readf32 = buffer.readf32

function to_roblox_string(b: buffer, start: number): (number, string)
	local len = readu32(b, start)
	start += 4
	return start + len, buffer.readstring(b, start, len)
end

-- boolean
function to_boolean(b: buffer, start: number): (number, boolean)
	return start + 1, readu8(b, start) == 0x01
end

-- i32
function int_detransform(x: number): number
	return if x % 2 == 0
		then x / 2
		else -(x + 1) / 2
end

-- note: works for undoing singular bytes, consider collection of bytes
function byte_interleave(b: buffer, start: number, rows: number, columns: number)
	local accessed = {}
	
	local i_local = 0
	local n_local = rows * columns
	
	while i_local < n_local do
		local r_local = i_local % columns
		local c_local = i_local // columns
		local value_global = readu8(b, start + i_local)
		local j_local = r_local * rows + c_local
		
		while not accessed[j_local] do
			accessed[j_local] = true
			local temp = readu8(b, start + j_local)
			buffer.writeu8(b, start + j_local, value_global)
			value_global = temp
			
			r_local = j_local % columns
			c_local = j_local // columns
			j_local = r_local * rows + c_local
		end
		
		i_local += 1
	end
end

function to_int32(b: buffer, start: number): (number, number)
	return start + 4, int_detransform(buffer.readu32(b, start))
end

-- f32
function to_f32(b: buffer, start: number): (number, number)
	local x = readu32(b, start)
	x = bit32.rrotate(x, 1)
	buffer.writeu32(b, start, x)
	return start + 4, readf32(b, start)
end

-- f64
function to_f64(b: buffer, start: number): (number, number)
	return start + 8, buffer.readf64(b, start)
end

-- udim
function to_udim(b: buffer, start: number): (number, UDim)
	return start + 8, UDim.new(
		readf32(b, start),
		buffer.readi32(b, start + 4)
	)
end

-- udim2
function to_udim2(b: buffer, start: number): (number, UDim2)
	local x, y;
	start, x = to_udim(b, start)
	start, y = to_udim(b, start)
	
	return start, UDim2.new(x, y)
end

-- brickcolor
function to_brickcolor(b: buffer, start: number): (number, BrickColor)
	return start + 4, BrickColor.new(readu32(b, start))
end

-- color3f
function to_color3f(b:buffer, start: number): (number, Color3)
	return start + 12, Color3.new(
		readf32(b, start),
		readf32(b, start + 4),
		readf32(b, start + 8)
	)
end

-- vector2
function to_vector2(b: buffer, start: number): (number, Vector2)
	return start + 8, Vector2.new(
		readf32(b, start),
		readf32(b, start + 4)
	)
end

-- vector3
function to_vector3(b: buffer, start: number): (number, Vector3)
	return start + 12, Vector3.new(
		readf32(b, start),
		readf32(b, start + 4),
		readf32(b, start + 8)
	)
end

-- cframe
-- subjected to change due to structure differences between attributes and actual instances
function to_cframe(b: buffer, start: number): (number, CFrame)
	local p
	start, p = to_vector3(b, start)
	
	local orientation_type = readu8(b, start)
	start += 1
	
	local R0, R1, R2
	
	if orientation_type > 0 then
		orientation_type -= 1
		R0 = Vector3.fromNormalId(orientation_type / 6)
		R1 = Vector3.fromNormalId(orientation_type % 6)
		R2 = R0:Cross(R1)
	else
		start, R0 = to_vector3(b, start)
		start, R1 = to_vector3(b, start)
		start, R2 = to_vector3(b, start)
	end
	
	return start, CFrame.fromMatrix(p, R0, R1, R2)
end

module.data_types = {
	string     = to_roblox_string;
	boolean    = to_boolean;
	int32      = to_int32;
	float32    = to_f32;
	float64    = to_f64;
	udim       = to_udim;
	udim2      = to_udim2;
	brickcolor = to_brickcolor;
	color3f    = to_color3f;
	vector2    = to_vector2;
	vector3    = to_vector3;
	cframe     = to_cframe;
}

module.byte_interleave = byte_interleave
module.int_detransform = int_detransform

return module
