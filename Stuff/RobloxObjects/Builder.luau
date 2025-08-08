local Map = require('./@CHL>Map')
local Object = require('./Object')

export type object<product> = {
	map: Map.dictionary<any>;
	constructor: <A...>(A...)->product;
	
	build: (self: object<product>)->product;
}

export type mutator<self, v_type> = (self: self, value: v_type)->self;

local module = {}

function module.new<P>(): object<P>
	local self: object<P> = Object.simple.new(module)
	self.map = {}
	return self
end

function module.build<product>(self: object<product>)
	local result = self.constructor()
	
	for i, v in self.map do
		result[i] = v
	end
	
	return result
end

function module.generate_mutators(class: any, strs: {string})
	for _, v in strs do
		class[`set_{v}`] = function<A>(self: object<A>, w)
			self.map[v] = w
		end
	end
end

module.__index = module

return module
