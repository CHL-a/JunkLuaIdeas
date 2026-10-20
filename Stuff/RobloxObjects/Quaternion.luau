--[[
	from @daymxn/LuaQuaternion edit to hopefully improve code and performance

	https://github.com/daymxn/LuaQuaternion
]]

export type struct = {
	x: number,
	y: number,
	z: number,
	w: number,
}

local module = {}
struct = {}

function module.safe_unit(v3: Vector3, default: Vector3): Vector3
	if v3.Magnitude > module.epsilon then
		return v3.Unit
	end
	return default
end

function module.orthonormalize_trivector(right: Vector3, up: Vector3, back: Vector3): (Vector3, Vector3, Vector3)
	right = module.safe_unit(right, Vector3.xAxis)
	up = module.safe_unit(up, Vector3.yAxis)
	
	local z_basis = right:Cross(up)
	
	if z_basis.Magnitude > module.epsilon then
		z_basis = z_basis.Unit
	else
		z_basis = right:Cross(Vector3.yAxis)
		if z_basis.Magnitude > module.epsilon then
			z_basis = z_basis.Unit
		else
			z_basis = Vector3.xAxis
		end
	end
	
	local y_basis = z_basis:Cross(right).Unit
	
	if z_basis:Dot(back) < 0 then
		z_basis = -z_basis
	end
	
	return right, y_basis, z_basis
end

module.epsilon = 5E-10

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

--[[
	Note:
		Under this lib, all from_ methods are constructors,
		all self_ methods are inplace methods that modified arg 1
]]

local Dash = require('./@roblox>Dash')

Dash.promise:await()

compose = Dash.compose

function struct.new(x: number?, y: number?, z: number?, w: number?): struct
	return {
		x = x or 0;
		y = y or 0;
		z = z or 0;
		w = w or 1;
	}
end

function struct.from_axis_angle_closure(axis: Vector3, angle: number): struct	
	angle /= 2
	local sin_ha = math.sin(angle)
	axis *= sin_ha
	
	local x = axis.X
	local y = axis.Y
	local z = axis.Z
	local w = math.cos(angle)
	
	return struct.new(x, y, z, w)
end

function struct.from_axis_angle(axis: Vector3, angle: number): struct
	axis = module.safe_unit(axis, Vector3.xAxis)
	
	return struct.from_axis_angle_closure(axis, angle)
end

function struct.from_euler_vector(euler_vector: Vector3): struct
	local angle = euler_vector.Magnitude
	if angle > 0 then
		local axis = euler_vector / angle
		return struct.from_axis_angle_closure(axis, angle)
	else
		return table.clone(struct.identity)
	end
end

function struct.from_cframe(cframe: CFrame): struct
	local axis, angle = cframe:Orthonormalize():ToAxisAngle()
	return struct.from_axis_angle(axis, angle)
end

function struct.from_cframe_fast(cframe: CFrame): struct
	local axis, angle = cframe:ToAxisAngle()
	return struct.from_axis_angle_closure(axis, angle)
end

function struct.from_orthonormalized_matrix(vX: Vector3, vY: Vector3, vZ: Vector3?): struct
	local m00, m10, m20 = vX.X, vX.Y, vX.Z
	local m01, m11, m21 = vY.X, vY.Y, vY.Z
	local m02, m12, m22 = vZ.X, vZ.Y, vZ.Z
	
	local trace = m00 + m11 + m22
	
	local qX, qY, qZ, qW
	
	if trace > 0 then
		local S = math.sqrt(trace + 1) * 2
		qX = (m21 - m12) / S;
		qY = (m02 - m20) / S; 
		qZ = (m10 - m01) / S; 
		qW = 0.25 * S;
	elseif m00 > m11 and m00 > m22 then
		local S = math.sqrt(1 + m00 - m11 - m22) * 2
		qX = 0.25 * S;
		qY = (m01 + m10) / S; 
		qZ = (m02 + m20) / S; 
		qW = (m21 - m12) / S;
	elseif m11 > m22 then
		local S = math.sqrt(1 + m11 - m00 - m22) * 2
		qX = (m01 + m10) / S; 
		qY = 0.25 * S;
		qZ = (m12 + m21) / S; 
		qW = (m02 - m20) / S;
	else
		local S = math.sqrt(1 + m22 - m00 - m11) * 2
		qX = (m02 + m20) / S;
		qY = (m12 + m21) / S;
		qZ = 0.25 * S;
		qW = (m10 - m01) / S;
	end
	
	return struct.new(qX, qY, qZ, qW)
end

function struct.from_matrix_fast(vX: Vector3, vY: Vector3, vZ: Vector3?): struct
	vZ = vZ or vX:Cross(vY).Unit
	return struct.from_orthonormalized_matrix(vX.Unit, vY.Unit, vZ)
end

function struct.from_matrix(vX: Vector3, vY: Vector3, vZ: Vector3?): struct
	vZ = vZ or vX:Cross(vY)
	return struct.from_orthonormalized_matrix(module.orthonormalize_trivector(vX, vY, vZ))
end

function struct.look_at(from: Vector3, look_at_v3: Vector3, up: Vector3?): struct
	look_at_v3 = module.safe_unit(look_at_v3 - from, Vector3.zAxis)
	up = module.safe_unit(up or Vector3.yAxis, Vector3.yAxis)
	
	local right = look_at_v3:Cross(up)
	local epsilon = module.epsilon
	local select_v3 = look_at_v3:Cross(Vector3.xAxis)
	
	if right.Magnitude > epsilon then
		right = right.Unit
		up = right:Cross(look_at_v3).Unit
	elseif select_v3.Magnitude > epsilon then
		right = select_v3.Unit
		up = right:Cross(look_at_v3).Unit
	else
		up = Vector3.zAxis:Cross(look_at_v3)
		up *= up:Dot(Vector3.yAxis)
		right = look_at_v3:Cross(up)
	end
	
	return struct.from_orthonormalized_matrix(right, up, -look_at_v3)
end

struct.euler_angles_signs = {
	['XYZ'] = { 1, -1,  1, -1};
	['ZYX'] = {-1,  1, -1,  1};
	['YXZ'] = { 1, -1, -1,  1};
	['ZXY'] = {-1,  1,  1, -1};
	['YZX'] = { 1,  1, -1, -1};
	['XZY'] = {-1, -1,  1,  1};
}

function struct.from_euler_angles(rx: number, ry: number, rz: number, rotation_order: Enum.RotationOrder?): struct
	rotation_order = rotation_order or Enum.RotationOrder.XYZ
	rx /= 2
	ry /= 2
	rz /= 2
	
	local cos = math.cos
	local sin = math.sin
	
	local x_cos = cos(rx)
	local y_cos = cos(ry)
	local z_cos = cos(rz)
	
	local x_sin = sin(rx)
	local y_sin = sin(ry)
	local z_sin = sin(rz)
	
	local x_sin_y_cos = x_sin * y_cos
	local x_cos_y_sin = x_cos * y_sin
	local x_cos_y_cos = x_cos * y_cos
	local x_sin_y_sin = x_sin * y_sin
	
	local s_x, s_y, s_z, s_w = unpack(module.euler_angles_signs[rotation_order.Name])
	
	local x = x_sin_y_cos * z_cos + x_cos_y_sin * z_sin * s_x
	local y = x_cos_y_sin * z_cos + x_sin_y_cos * z_sin * s_y
	local z = x_cos_y_cos * z_sin + x_sin_y_sin * z_cos * s_z
	local w = x_cos_y_cos * z_cos + x_sin_y_sin * z_sin * s_w
	
	return struct.new(x, y, z, w)
end

function struct.from_euler_angles_xyz(rx: number, ry: number, rz: number): struct
	return struct.from_euler_angles(rx, ry, rz, Enum.RotationOrder.XYZ)
end

function struct.from_euler_angles_yxz(rx: number, ry: number, rz: number): struct
	return struct.from_euler_angles(rx, ry, rz, Enum.RotationOrder.YXZ)
end

function struct.from_vector(v3: Vector3, w: number?): struct
	return struct.new(v3.X, v3.Y, v3.Z, w or 0)
end

function struct.from_random(random: Random): struct
	local sqrt = math.sqrt
	local tau = math.tau
	local sin = math.sin
	local cos = math.cos
	
	local u = random:NextNumber(0, 1)
	local v = random:NextNumber(0, 1)
	local w = random:NextNumber(0, 1)
		
	local omu = 1 - u
	local squ = sqrt(u)
	local sqmu = sqrt(omu)
		
	local tpv = tau * v
	local tpw = tau * w
		
	local qX = sqmu * sin(tpv)
	local qY = sqmu * cos(tpv)
	local qZ = squ * sin(tpw)
	local qW = squ * cos(tpw)
	
	return struct.new(qX, qY, qZ, qW)
end

function struct.self_add(self: struct, other: struct): struct
	self.x += other.x
	self.y += other.y
	self.z += other.z
	self.w += other.w
	return self
end

function struct.self_sub(self: struct, other: struct): struct
	self.x -= other.x
	self.y -= other.y
	self.z -= other.z
	self.w -= other.w
	return self
end

function struct.get_components(self: struct): (number, number, number, number)
	return self.x, self.y, self.z, self.w
end

function struct.self_mul(self: struct, other: struct): struct
	local x_0, y_0, z_0, w_0 = struct.get_components(self)
	local x_1, y_1, z_1, w_1 = struct.get_components(other)
	
	self.x = w_0 * x_1 + x_0 * w_1 + y_0 * z_1 - z_0 * y_1
	self.y = w_0 * y_1 - x_0 * z_1 + y_0 * w_1 + z_0 * x_1
	self.z = w_0 * z_1 + x_0 * y_1 - y_0 * x_1 + z_0 * w_1
	self.w = w_0 * w_1 - x_0 * x_1 - y_0 * y_1 - z_0 * z_1
	
	return self
end

function struct.self_scalar_mul(self: struct, scale: number): struct
	self.x *= scale
	self.y *= scale
	self.z *= scale
	self.w *= scale
	return self
end

function struct.combine_imaginary(self: struct, v3: Vector3): struct
	return struct.self_mul(struct.from_vector(v3), self)
end

function struct.length_sqrd(self: struct): number
	local x, y, z, w = struct.get_components(self)
	return x*x + y*y + z*z + w*w
end

function struct.self_conjugate(self: struct): struct
	self.x = -self.x
	self.y = -self.y
	self.z = -self.z
	
	return self
end

function struct.self_scalar_div(self: struct, scale: number): struct
	return struct.self_scalar_mul(self, 1 / scale)
end

function struct.self_inverse(self: struct): struct
	local length = struct.length_sqrd(self)
	
	struct.self_conjugate(self)
	struct.self_scalar_div(self, length)
	return self
end

function struct.self_div(self: struct, other: struct): struct
	return struct.self_mul(self, struct.inverse(other))
end

function struct.self_unary(self: struct): struct
	self.x = -self.x
	self.y = -self.y
	self.z = -self.z
	self.w = -self.w
	return self
end

function struct.self_set(self: struct, other: struct): struct
	self.x = other.x
	self.y = other.y
	self.z = other.z
	self.w = other.w
	
	return self
end

function struct.self_pow(self: struct, num: number): struct
	if num == -1 then return struct.self_inverse(self) end
	
	local x, y, z, w = struct.get_components(self)
	local length = struct.length(self) -- aIm
	local xyz_length_sqrd = struct.length_sqrd(self) - w * w
	local xyz_length = math.sqrt(xyz_length_sqrd) -- aMag
	local powd = xyz_length ^ num -- cMag
	
	if length <= module.epsilon * xyz_length then
		struct.self_set(self, struct.zero)
		self.w = powd
		
		return self
	end
	
	local ang = math.atan2(length, w) * num
	local ang_cos, ang_sin = math.cos(ang), math.sin(ang)
	local powd_a_sin = ang_sin * powd
	
	self.x = powd_a_sin * x / length
	self.y = powd_a_sin * y / length
	self.z = powd_a_sin * z / length
	self.w = ang_cos * powd
	
	return self
end

function struct.is_equal(self: struct, other: struct): boolean
	return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w
end

function struct.length(self: struct): number
	return struct.length_sqrd(self) ^ 0.5
end

function struct.less_than(self: struct, other: struct): boolean
	local s_length = struct.length(self)
	local o_length = struct.length(other)
	
	return s_length < o_length
end

function struct.less_equal(self: struct, other: struct): boolean
	local s_length = struct.length(self)
	local o_length = struct.length(other)
	
	return s_length <= o_length
end

function struct.self_exp(self: struct): struct
	local x, y, z, w = struct.get_components(self)
	
	local m = math.exp(w)
	local vv = x*x + y*y + z*z
	if vv > 0 then
		local v = vv ^ 0.5
		local s = m * math.sin(v) / v
		
		x *= s
		y *= s
		z *= s
		w = m * math.cos(v)
	else
		x = 0
		y = 0
		z = 0
		w = m
	end
	
	self.x = x
	self.y = y
	self.z = z
	self.w = w
	
	return self
end

function struct.self_exp_map(self: struct, other: struct): struct
	other = struct.exp(other)
	
	return struct.self_mul(self, other)
end

function struct.self_log(self: struct): struct
	local x, y, z, w = struct.get_components(self)
	local vv = x*x + y*y + z*z
	local mm = w*w + vv
	
	if mm <= 0 then
		x = 0
		y = 0
		z = 0
		w = -1/0
		elseif vv > 0 then
		local m = mm ^ 0.5
		local s = math.acos(w / m) / (vv ^ 0.5)
		
		x *= s
		y *= s
		z *= s
		w = math.log(m)
	else
		x = 0
		y = 0
		z = 0
		w = math.log(mm)/2
	end
	
	self.x = x
	self.y = y
	self.z = z
	self.w = w
	
	return self
end

function struct.self_log_map(self: struct, from: struct): struct
	return struct.self_log(struct.self_mul(struct.self_inverse(self), from))
end

function struct.hypot(self: struct): number
	local large = math.max(struct.get_components(self))
	
	if large > 0 then
		local normalized = struct.scalar_div(self, large)
		local length = struct.length(normalized) * large
		
		return length
	end
	
	return 0
end

function struct.self_normalize(self: struct): struct
	local length = struct.length(self)
	
	if length > 0 then
		return struct.self_scalar_div(self, length)
	else
		return struct.self_set(self, struct.identity)
	end
end

function struct.is_unit(self: struct, epsilon: number?): boolean
	epsilon = epsilon or module.epsilon
	return math.abs(1 - struct.length(self)) < epsilon
end

function struct.to_cframe(self: struct, position: Vector3?): CFrame
	position = position or Vector3.zero
	
	self = struct.normalize(self)
	
	return CFrame.new(
		position.X,
		position.Y,
		position.Z,
		self.x,
		self.y,
		self.z,
		self.w
	)
end

function struct.dot(self: struct, other: struct): number
	return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
end

--[[
	To denote the difference between sub and difference, difference is now q_difference
]]
function struct.self_q_difference(self: struct, other: struct): struct
	if struct.dot(self, other) < 0 then
		struct.self_unary(self)
	end
	
	return struct.self_mul(struct.self_inverse(self), other)
end

function struct.self_s_lerp(self: struct, other: struct, alpha: number): struct
	struct.self_normalize(self)
	other = struct.normalize(other)
	
	local dot = struct.dot(self, other)
	
	if dot < 0 then
		struct.self_unary(other)
		dot = -dot
	end
	
	if dot >= 1 then
		return struct.self_normalize(
			struct.self_add(
				self,
				struct.self_scalar_mul(
					struct.self_sub(other, self),
					alpha
				)
			)
		)
	end
	
	local theta_0 = math.acos(dot)
	local theta = theta_0 * alpha
	
	local sin_theta_0 = math.sin(theta_0)
	local sin_theta = math.sin(theta)
	
	local s_1 = sin_theta / sin_theta_0
	local s_0 = math.cos(theta) - dot * s_1
	
	return struct.self_normalize(
		struct.self_add(
			struct.self_scalar_mul(self, s_0),
			struct.self_scalar_mul(other, s_1)
		)
	)
end

function struct.self_integrate(self: struct, rate: Vector3, timestep: number): struct
	struct.self_normalize(self)
	
	local rotation = rate * timestep
	
	if rotation.Magnitude <= 0 then
		return self
	end
	
	local axis = rotation.Unit
	local q_1 = struct.from_axis_angle(axis, rotation.Magnitude)
	
	return struct.self_normalize(struct.self_mul(self, q_1))
end

function struct.to_vector3(self: struct): Vector3
	return Vector3.new(self.x, self.y, self.z)
end

function struct.to_axis_angle(self: struct): (Vector3, number)
	self = struct.normalize(self)
	local w = self.w
	
	local angle = 2 * math.acos(w);
	local s = math.sqrt(1 - w * w);
	local axis = struct.to_vector3(self)
	
	if s >= module.epsilon then
		axis /= s
	end
	
	return axis, angle
end

function struct.to_euler_vector(self: struct): Vector3
	local axis, angle = struct.to_axis_angle(self)
	return axis * angle
end

function struct.exp_map_sym(self: struct, other: struct): struct
	local sqrt_self = struct.pow(self, .5)
	local exp_other = struct.exp(other)
	local mul = struct.mul
	
	return mul(mul(sqrt_self, exp_other), sqrt_self)
end

function struct.log_map_sym(self: struct, other: struct): struct
	local inv_sqrt_self = struct.pow(self, -1/2)
	local mul = struct.mul
	
	return struct.self_log(mul(mul(inv_sqrt_self, other), inv_sqrt_self))
end

function struct.distance(self: struct, other: struct): number
	return struct.length(struct.log_map(self, other)) * 2
end

function struct.non_implace(self: struct, ...) return table.clone(self), ... end

struct.add = compose(struct.non_implace, struct.self_add) :: (struct, struct) -> struct
struct.log_map = compose(struct.non_implace, struct.self_log_map) :: (struct, struct) -> struct
struct.mul = compose(struct.non_implace, struct.self_mul) :: (struct, struct) -> struct
struct.pow = compose(struct.non_implace, struct.self_pow) :: (struct, number) -> struct
struct.inverse = compose(struct.non_implace, struct.self_inverse) :: (struct) -> struct
struct.exp = compose(struct.non_implace, struct.self_exp) :: (struct) -> struct
struct.scalar_div = compose(struct.non_implace, struct.self_scalar_div) :: (struct, number) -> struct
struct.normalize = compose(struct.non_implace, struct.self_normalize) :: (struct) -> struct
struct.s_lerp = compose(struct.non_implace, struct.self_s_lerp) :: (struct, struct, number) -> struct
struct.integrate = compose(struct.non_implace, struct.self_integrate) :: (struct, Vector3, number) -> struct
struct.q_difference = compose(struct.non_implace, struct.self_q_difference) :: (struct, struct) -> struct

struct.identity = struct.new(0, 0, 0, 1)
struct.zero = struct.new(0, 0, 0, 0)
struct.angles = struct.from_euler_angles_xyz
struct.from_orientation = struct.from_euler_angles_yxz
struct.unit = struct.normalize
struct.magnitude = struct.length

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

local UnitTest = require('./@CHL>UnitTest')

function struct.unit_test(describe: UnitTest.describe)
	local q = struct.new(1, 2, 3, 4)
	
	describe('struct: Iq == qI', function(expect)
		expect(struct.mul(q, struct.identity)).to_span_fields_over(q)
		expect(struct.mul(struct.identity, q)).to_span_fields_over(q)
	end)
	
	local q = struct.new(1, 2, 3, 4)
	local zero = struct.new(0, 0, 0, 0)

	describe('struct: q + (-q) == 0', function(expect)
		expect(struct.add(q, struct.self_unary(table.clone(q))))
			.to_span_fields_over(zero)
	end)
	
	local a = struct.new(1, 2, 3, 4)
	local b = struct.new(5, 6, 7, 8)
	local c = struct.new(9, 10, 11, 12)

	describe('struct: (ab)c == a(bc)', function(expect)
		expect(
			struct.mul(struct.mul(a, b), c)
		).to_span_fields_over(
			struct.mul(a, struct.mul(b, c))
		)
	end)
	
	local a = struct.new(1, 2, 3, 4)
	local b = struct.new(5, 6, 7, 8)
	local c = struct.new(9, 10, 11, 12)

	describe('struct: (ab)c == a(bc)', function(expect)
		expect(
			struct.mul(struct.mul(a, b), c)
		).to_span_fields_over(
			struct.mul(a, struct.mul(b, c))
		)
	end)
	
	local a = struct.new(1, 2, 3, 4)
	local b = struct.new(5, 6, 7, 8)

	describe('struct: length(ab) == length(a) * length(b)', function(expect)
		expect(struct.length(struct.mul(a, b))).to_be_around(struct.length_sqrd(a))
	end)
	
	local q = struct.new(1, 2, 3, 4)
	local inverse = struct.inverse(q)

	describe('struct: qq^-1 == q^-1q == I', function(expect)
		expect(struct.mul(q, inverse)).to_span_fields_around_over(struct.identity)
		expect(struct.mul(inverse, q)).to_span_fields_around_over(struct.identity)
	end)
end

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

export type object = {
	to_struct: (self: object) -> struct;
	clone: (self: object) -> object;
	
	s_lerp: (self: object, object, number) -> object;
	integrate: (self: object, Vector3, number) -> object;
	q_difference: (self: object, object) -> object;
	to_euler_vector: (self: object) -> Vector3;
	to_cframe: (self: object) -> CFrame;
} & struct

local Object = require('./Object')
local Class = require('./Class')

object = {}

function object.from_struct(s: struct): object
	return Object.simple.from.struct(s, object)
end

function object.to_struct(self: object): struct
	return struct.new(self.x, self.y, self.z, self.w)
end

function object.clone(self: object): object
	return object.from_struct(self:to_struct())
end

function object.non_implace(self: object, ...)
	return self:to_struct(), ...
end

object.from_cframe = compose(struct.from_cframe, object.from_struct) :: (CFrame) -> object

object.s_lerp = compose(object.non_implace, struct.self_s_lerp, object.from_struct) :: (object, object, number) -> object
object.integrate = compose(object.non_implace, struct.self_integrate, object.from_struct) :: (object, Vector3, number) -> object
object.q_difference = compose(object.non_implace, struct.self_q_difference, object.from_struct) :: (object, object) -> object
object.to_euler_vector = struct.to_euler_vector
object.to_cframe = struct.to_cframe

object.new = compose(struct.new, object.from_struct) :: (number?, number?, number?, number?) -> object

object.identity = object.from_struct(struct.identity)
object.zero = object.from_struct(struct.zero)

Class.make_proper_class(object, '@CHL>Quaternion')

--#############################################################################################################################################################################
--#############################################################################################################################################################################
--#############################################################################################################################################################################

module.struct = struct
module.object = object

function module.unit_test(...)
	struct.unit_test(...)
end

return module
