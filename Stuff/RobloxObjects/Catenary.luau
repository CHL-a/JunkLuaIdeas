--[[
	Catenary
	
	Believe it or not, ropes turns out to be catenaries not parabolas
	
	A catenary is the shape taken by a rope or chain hanging from two points. In this instance, and typical case, we define the y axis to the
	direction of the peak, in either direction, as the primary axis, while the other axes, x and z, as secondary
	
	The typical equation for a catenary is:
	
	y = a * cosh(x/a)
	
	Where:
	 * a is a parameter that depends on the properties of the rope and the force holding the rope to the points,
	   concerningly, the upcoming equation turns out to be transcendental
	 * cosh is the hyperbolic cosine, aka math.cosh and etc for many related hyperbolic functions
	
	Furthermore, more variables can be defined from the above definition, for instance,
	
	displacement between two given points, p_0 and p_1, which defines:
	  * v: as the displacement within the primary axis
	  * h: as the displacement within the secondary axes
	  * l: as the length of the rope
	
	then:
	
	sqrt(l^2 - v^2) = 2a * sinh(h / (2a))
	
	which, in this case is considered transcendental, and thus a had to be found using a binary (group) search
	
	even with a, we may have to consider the possibility that the equation itself might want to be altered by displacement, so we propose to 
	extend the equation from a simple equation to
	
	y = a * cosh((x - p) / a) + q
	
	Where:
	  * p is the secondary axes displacement and
	  * q is the primary axis displacement
	
	For purposes of using a 3d version of a catenary, we can say that a plane is defined, where the primary axis, y in 3d space is the 
	primary axis, y in 2d space
	
	alternatively, we can define the secondary axis in 2d space as a combination of the secondary axes in 3d space, x and z as a unit vector,
	pointing in the direction of the two points
	
	alan formally define our two displacement variables in 2d space as:
	p = (x_0 + x_1 - a*ln((l + v) / (l - v))) / 2
	q = (y_1 + y_0 - l*coth(h/(2a))) / 2
	
	Sources:
	 * https://en.wikipedia.org/wiki/Catenary#Derivation_of_equations_for_the_curve
	 * https://www.alanzucconi.com/2020/12/13/catenary-1/#id436391346
]]

local module = {}

--################################################################################################################################################
--################################################################################################################################################
--################################################################################################################################################

dimension_2 = {}

sinh = math.sinh
abs = math.abs

--[[
	returns x * sinh(h / x), which I define as a curve function
]]
function dimension_2.curve(h: number, x: number): number return x * sinh(h / x)end

export type curve_query = {
	asymptote: number, -- aka h
	max_limits: number?;
	start_at: number?;
	check_value: number;
	imprecision_gap: number?;
	-- subjected to have its own predicate functions
}

--[[
	Returns x such that check_value == x * sinh(h / x), or in other words,
	
	it is curve^-1(...)
]]
function dimension_2.curve_inverse(query: curve_query): number
	local h = query.asymptote
	local max_limit = query.max_limits or 10
	local check_curve = query.check_value
	local imprecision = query.imprecision_gap or 1E-3
	
	local iterate = dimension_2.curve
	
	local iterations = 1
	
	local current_x = query.start_at or .01
	local current_curve = iterate(h, current_x)
	
	while current_curve > check_curve and
		iterations < max_limit do
		iterations += 1
		current_x *= 2
		current_curve = iterate(h, current_x)
	end
	
	local min_x = current_x / 2
	local max_x = current_x
	
	current_x = (min_x + max_x) / 2
	current_curve = iterate(h, current_x)
	
	while iterations < max_limit do
		iterations += 1
		
		if current_curve == check_curve then
			return current_x
		elseif current_curve < check_curve then
			max_x = current_x
		else
			min_x = current_x
		end
		
		current_x = (min_x + max_x) / 2
		current_curve = iterate(h, current_x)
		
		if abs(max_x - min_x) < imprecision then
			break
		end
	end
	
	return current_x
end

function dimension_2.curve_param(p_0: Vector2, p_1: Vector2, length: number)
	local displacement = p_1 - p_0
	
	if displacement.Magnitude == 0 
		or displacement.Magnitude >= length 
	then
		return 0
	end
	
	local v = displacement.Y
	local h = displacement.X
	local l = length
	
	local check = sqrt(l ^ 2 - v ^ 2)
	
	local a = dimension_2.curve_inverse({
		asymptote = h,
		check_value = check;
		max_limits = 100;
	})
	
	return a / 2
end

--[[
	Attempts to get y = sinh((x_1 - p) / a)
	
	to compare with:
	L = a * sinh((x_1 - p) / a) - a * sinh((x_0 - p) / a)
	
	where p is the offset used earlier
	
	we can arrange above to construct a function that uses the least amount of operations, specifically, we can suppose that:
	x_0 since the purpose of this module uses p_0 as (0,0)
	
	L = a * ( sinh((x_1 - p) / a) - sinh((0 - p) / a) )
	La = sinh((x_1 - p) / a) - sinh(-p / a)
	La + sinh(-p / a) = sinh((x_1 - p) / a)
]]
function dimension_2.l_function(x_1, p, a)return sinh((x_1 - p) / a)end

export type l_query = {
	curve_value: number, -- aka a
	p_offset: number, -- aka p
	max_limits: number?;
	check_value: number;
	imprecision_gap: number?;
	-- subjected to have its own predicate functions
}

--[[
	Attempts to get x from l_function
]]
function dimension_2.l_function_inverse(query: l_query): number
	local curve = query.curve_value
	local max_limit = query.max_limits or 10
	local check = query.check_value
	local imprecision = query.imprecision_gap or 1E-3
	local iterate = dimension_2.l_function
	local p = query.p_offset
	
	local iterations = 1
	
	local is_positive = check > 0
	local check_sign = math.sign(check)
	local mult = 1
	local current_x = p
	local current_check = iterate(current_x, p, curve)
	local min_x = p
	local max_x = p
	
	if current_check < check then
		while current_check < check and iterations < max_limit do
			iterations += 1
			current_x = p + mult
			mult *= 2
			current_check = iterate(current_x, p, curve)
		end
		
		min_x = p + mult / 4 // 1
		max_x = current_x
	else
		while current_check > check and iterations < max_limit do
			iterations += 1
			current_x = p - mult
			mult *= 2
			current_check = iterate(current_x, p, curve)
		end
		
		min_x = current_x
		max_x = p - mult / 4 // 1
	end
	
	current_x = (min_x + max_x) / 2
	current_check = iterate(current_x, p, curve)
	
	while iterations < max_limit do
		iterations += 1
		
		if current_check == check then
			break
		elseif current_check < check then
			min_x = current_x
		else
			max_x = current_x
		end
		
		if abs(max_x - min_x) < imprecision then
			break
		end
		
		current_x = (min_x + max_x) / 2
		current_check = iterate(current_x, p, curve)
	end
	
	return current_x
end

--################################################################################################################################################
--################################################################################################################################################
--################################################################################################################################################

-- parametric approach of the catenary curve

local Class = require('./Class')
local Object = require('./Object')
local Math = require('./@CHL>Math')

export type curve_2d = {
	point_0: Vector2;
	point_1: Vector2;
	length: number;
	curve_param: number;
	changed_states: boolean; -- optimization to prevent invoking inverse curve function
	
	get_curve_param: (self: curve_2d) -> number;
	set_curve_param: (self: curve_2d, new_curve_param: number) -> ();
	set_length: (self: curve_2d, new_length: number) -> ();
	set_point_0: (self: curve_2d, new_point: Vector2) -> ();
	set_point_1: (self: curve_2d, new_point: Vector2) -> ();
	point_at: (self: curve_2d, t: number) -> Vector2;
	get_x_from_length: (curve: curve_2d, length: number) -> number;
	call: (self: curve_2d, x: number) -> Vector2;
	get_p: (self: curve_2d)-> number;
}

ln = Math.log.nat
coth = Math.hyperbolic.coth
cosh = math.cosh

function dimension_2.new(point_0: Vector2, point_1: Vector2, length: number?): curve_2d
	local self: curve_2d = Object.simple.new(dimension_2)
	
	self.changed_states = false
	self.point_0 = point_0
	self.point_1 = point_1
	self.length = length or (point_0 - point_1).Magnitude
	
	self:set_length(self.length)
	
	return self
end

function dimension_2.get_curve_param(self: curve_2d): number
	if not self.changed_states then
		return self.curve_param
	end
	
	local result = dimension_2.curve_param(self.point_0, self.point_1, self.length)
	
	self.changed_states = false
	
	self:set_curve_param(result)
	
	return result
end

function dimension_2.set_curve_param(self: curve_2d, value) self.curve_param = value end

function dimension_2.set_length(self: curve_2d, value) self.length = value self.changed_states = true end
function dimension_2.set_point_0(self: curve_2d, value) self.point_0 = value self.changed_states = true end
function dimension_2.set_point_1(self: curve_2d, value) self.point_1 = value  self.changed_states = true end

function dimension_2.get_p(self: curve_2d):number
	local point_0 = self.point_0
	local point_1 = self.point_1
	local a = self:get_curve_param()
	local l = self.length
	local v = point_1.Y - point_0.Y
	
	local p = (point_0.X + point_1.X - a * ln( (l + v) / (l - v) ) ) / 2
	
	return p
end

function dimension_2.call(self: curve_2d, x: number)
	local point_0 = self.point_0
	local point_1 = self.point_1
	local relative = point_1 - point_0
	local l = self.length
	
	local a = self:get_curve_param()
	local h = abs(relative.X)
	local p = self:get_p()
	local q = (point_0.Y + point_1.Y - l * coth( h / (2 * a) )) / 2
	
	local y = a * math.cosh( (x - p) / a) + q
	
	return Vector2.new(x, y)
end

function dimension_2.get_x_from_length(self: curve_2d, length: number)
	local l = length
	local a = self:get_curve_param()
	local p = self:get_p()
	
	local check = l / a + sinh(-p/a)
	
	local l_query: l_query = {
		curve_value = a;
		p_offset = p;
		check_value = check;
		max_limits = 100;
	}
	
	return dimension_2.l_function_inverse(l_query)
end

function dimension_2.point_at(self: curve_2d, t: number)
	local point_0 = self.point_0
	local point_1 = self.point_1
	local relative = point_1 - point_0
	local magnitude = relative.Magnitude
	local l = self.length
	
	if magnitude >= l then
		-- case 1: straight line where the catenaries's length is exhausted, 
		local m = relative.Y / relative.X
		
		return point_0:Lerp(point_1, t)
	end
	
	local h = abs(relative.X)
	local alpha_length = t * l
	
	-- case 2: catenary has stacked positions, so a dynamic approach of evaluating is used here
	if h == 0 then
		-- by merging magnitude and length and then dividing the length by 2, then make alpha a length instead
		local result_y = math.max(point_0.Y, point_1.Y)
		
		local length_2 = (l + magnitude) / 2
		
		if point_0.Y < point_1.Y then
			alpha_length += magnitude
		end
		
		result_y -= math.min(alpha_length, length_2)
		result_y += math.max(0, alpha_length - length_2)
		
		return Vector2.xAxis * point_0 +
			Vector2.yAxis * result_y 
	end
	
	local x = self:get_x_from_length(alpha_length)
	
	return self:call(x)
end

Class.make_proper_class(dimension_2, '@CHL>Catenary>2D')

module.dimension_2 = dimension_2

--################################################################################################################################################
--################################################################################################################################################
--################################################################################################################################################

dimension_3 = {}
sqrt = math.sqrt

--################################################################################################################################################
--################################################################################################################################################
--################################################################################################################################################

export type curve_3d = {
	curve_2d: curve_2d;
	
	point_0: Vector3;
	point_1: Vector3;
	length: number;
	
	set_length: (self: curve_3d, new_length: number) -> ();
	set_point_0: (self: curve_3d, new_point: Vector3) -> ();
	set_point_1: (self: curve_3d, new_point: Vector3) -> ();
	point_at: (self: curve_3d, t: number) -> Vector3;
}

local Class = require('./Class')
local Object = require('./Object')

function dimension_3.new(p_0: Vector3, p_1: Vector3?, length: number?): curve_3d
	local self: curve_3d = Object.simple.new(dimension_3)
	local p_1 = p_1 or p_0
	
	self.point_1 = p_1
	self.curve_2d = dimension_2.new(Vector2.zero, Vector2.zero, 1)
	
	self:set_length(length or (p_0 - p_1).Magnitude )
	self:set_point_0(p_0)
	self:set_point_1(p_1)
	
	return self
end

function dimension_3.set_length(self: curve_3d, value)self.length = value self.curve_2d:set_length(value)end

function dimension_3.set_point_0(self: curve_3d, value)
	self.point_0 = value 
	
	local displacement = self.point_1 - self.point_0
	local lateral_magnitude = sqrt(displacement.X ^ 2 + displacement.Z ^ 2)
	
	self.curve_2d:set_point_1(
		Vector2.new(
			lateral_magnitude,
			displacement.Y
		)
	)
end

function dimension_3.set_point_1(self: curve_3d, value)
	self.point_1 = value
	
	local displacement = self.point_1 - self.point_0
	local lateral_magnitude = sqrt(displacement.X ^ 2 + displacement.Z ^ 2)
	
	self.curve_2d:set_point_1(
		Vector2.new(
			lateral_magnitude,
			displacement.Y
		)
	)
end

function dimension_3.point_at(self: curve_3d, alpha: number)
	local result = self.curve_2d:point_at(alpha)
	local displacement = self.point_1 - self.point_0
	local lateral_displacement = Vector3.new(displacement.X, 0, displacement.Z).Unit
	
	return self.point_0 + lateral_displacement * result.X + Vector3.yAxis * result.Y
end

Class.make_proper_class(dimension_3, '@CHL>Catenary')

--################################################################################################################################################
--################################################################################################################################################
--################################################################################################################################################

module.dimension_3 = dimension_3

return module
