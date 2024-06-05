--// TYPES
local Objects = script.Parent
local Object = require(Objects.Object)
local Map = require(Objects['@CHL/Map'])

type map<I,V> = Map.simple<I,V>
export type dist<T> = map<T, number>

export type object<T> = {
	distribution: dist<T>;
	random: Random;
	size: number;
	update_size: (self: object<T>) -> ();
	pick: (self: object<T>) -> T;
} & Object.object_inheritance;

--// MAIN
local module = {}

function module.new<T>(dist: dist<T>?, random: Random?): object<T>
	local self: object<T> = Object.from.class(module)
	self.size = 0
	self.random = random or module.default_random
	
	if dist then
		self.distribution = dist
		self:update_size()
	end

	return self
end

module.update_size = function<T>(self: object<T>)
	assert(self.distribution, 'Attempting to update size of non-existant distribution.')
	local size = 0
	
	for _, v in next, self.distribution do
		size += v
	end
	
	self.size = size
end

module.pick = function<T>(self: object<T>)
	assert(self.size >= 1, `Attempting to pick of low size: expected size\z
		>= 1, got: {self.size}`)
	
	local j = self.random:NextInteger(1,self.size)
	local result = next(self.distribution)
	
	while j > 0 do
		j = math.max(0, j - self.distribution[result])
		if j ~= 0 then
			result = next(self.distribution, result)
		end
	end
	
	return result
end

module.default_random = Random.new(0)
module.__index = module
module.className = 'PartsRandomizer'

return module
