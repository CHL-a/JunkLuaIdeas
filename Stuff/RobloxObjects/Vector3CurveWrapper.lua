local Objects = script.Parent
local Object = require(Objects.Object)
local TableUtils = require(Objects["@CHL/TableUtils"])
local Vector3Utils = require(Objects.Vector3Utils)
local Dash = require(Objects["@CHL/DashSingular"])

local module = {}

--##################################################################################
--##################################################################################
--##################################################################################

export type vector3CurvePoint = {
	value: Vector3;
	time: number;
	mode: Enum.KeyInterpolationMode;
}

Vector3CurvePoint = {}

function Vector3CurvePoint.imprint(
	result: vector3CurvePoint,
	v: Vector3,
	t: number,
	mode: Enum.KeyInterpolationMode?): vector3CurvePoint
	result.value = v;
	result.time = t;
	result.mode = mode or Enum.KeyInterpolationMode.Cubic
	return result
end

function Vector3CurvePoint.soft_imprint(
	result: vector3CurvePoint,
	v: Vector3,
	t: number,
	mode: Enum.KeyInterpolationMode?): vector3CurvePoint
	result.value = result.value or v;
	result.time = result.time or t;
	result.mode = result.mode or mode or Enum.KeyInterpolationMode.Cubic
	return result
end

function Vector3CurvePoint.new(
	v: Vector3, 
	t: number, 
	m: Enum.KeyInterpolationMode?): vector3CurvePoint
	return Vector3CurvePoint.imprint({}, v, t, m)
end

module.Vector3CurvePoint = Vector3CurvePoint;

--##################################################################################
--##################################################################################
--##################################################################################

export type constructor_args = {
	exclude: {
		x: boolean?;
		y: boolean?;
		z: boolean?;
	}?;
}

export type object = {
	c_args: constructor_args?;
	referral: Vector3Curve;
	list: {vector3CurvePoint};
	duration: number;
	
	get_float_curve_from_axis: (self: object, string) -> FloatCurve;
	get_position_unpacked: (self: object, runtime: number) -> (number?, number?, number?);
	get_position: (self: object, runtime: number) -> Vector3;
	get_cframe_p: (self: object, runtime: number) -> CFrame;
	get_cframe_r: (self: object, runtime: number, epsilon: number?) -> CFrame;
	get_cframe: (self: object, runtime: number, epsilon: number?) -> CFrame;
}

module.default_c_args = {
	exclude = {
		x = false;
		y = false;
		z = false;
	}
} :: constructor_args

disguise = require(Objects.LuaUTypes).disguise

function module.new(list: {vector3CurvePoint}, c_args: constructor_args?): object
	local self: object = Object.from.class(module)
	self.c_args = c_args
	self.referral = Instance.new('Vector3Curve')
	self.list = list
	self.duration = Dash.last(list).time
	
	local now_c_args = TableUtils.fill(c_args, module.default_c_args)
	local exclude = TableUtils.deepSoftIndex(now_c_args, 'exclude')
	
	for _, v in list do
		Vector3CurvePoint.soft_imprint(v)
		
		for w in module.default_c_args.exclude do
			if (exclude and exclude[w]) then continue end
			
			self:get_float_curve_from_axis(w)
				:InsertKey(
					FloatCurveKey.new(
						v.time, 
						v.value[w:upper()], 
						v.mode)
				)
		end
	end
	
	return self
end

module.from = {}

function module.from.list(list: {Vector3},
	duration: number,
	default_mode: Enum.KeyInterpolationMode?, 
	c_args: constructor_args?
	): object
	
	local length = Vector3Utils.between_magnitude_sum(list)
	local now = 0
	
	for i = 1, #list do
		if i > 1 then
			now += (disguise(list)[i-1].value - list[i]).Magnitude
		end
		
		list[i] = disguise({
			value = list[i];
			time = duration * (now / length);
			mode = default_mode or Enum.KeyInterpolationMode.Cubic
		} :: vector3CurvePoint)
	end
	
	return module.new(disguise(list), c_args)
end

function module.from.list_of_kspeed(list: {Vector3},
	kspeed: number,
	default_mode: Enum.KeyInterpolationMode?, 
	c_args: constructor_args?
): object

	local length = Vector3Utils.between_magnitude_sum(list)
	local now = 0

	for i = 1, #list do
		if i > 1 then
			now += (disguise(list)[i-1].value - list[i]).Magnitude
		end

		list[i] = disguise({
			value = list[i];
			time = (now / kspeed);
			mode = default_mode or Enum.KeyInterpolationMode.Cubic
		} :: vector3CurvePoint)
	end

	return module.new(disguise(list), c_args)
end


function module.get_float_curve_from_axis(self: object, s: string)
	if s == 'x' then
		return self.referral:X()
	elseif s == 'y' then
		return self.referral:Y()
	elseif s == 'z' then
		return self.referral:Z()
	else
		error(`Bad string for float curve: expected x,y or z, got: {s}`)
	end
end

function module.get_position_unpacked(self: object, now: number)
	return unpack(self.referral:GetValueAtTime(now))
end

function module.get_position(self: object, now: number)
	return Vector3.new(self:get_position_unpacked(now))
end

function module.get_cframe_p(self: object, now: number)
	return CFrame.new(self:get_position(now))
end

function module.get_cframe_r(self: object, now: number, epsilon: number?)
	return CFrame.lookAt(
		self:get_position(now), 
		self:get_position(now + (epsilon or .001))
	).Rotation
end

function module.get_cframe(self: object, now: number, epsilon: number?)
	return self:get_cframe_p(now) * self:get_cframe_r(now, epsilon)
end

module.__index = module
module.className = '@CHL/Vector3CurveWrapper'


return module
