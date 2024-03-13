--// TYPES
local Objects = script.Parent

export type object = {
	r: number;
	g: number;
	b: number;
	t: number;
	
	toString: (self: object) -> string;
	equals: (self: object, a: any) -> boolean;
}

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise
from = {}

function module.new(r: number, g: number, b: number, t: number): object
	local self: object = disguise(setmetatable({}, module))
	
	self.r = r
	self.g = g
	self.b = b
	self.t = t
	
	return self
end

function from.RGB(r:number,g:number,b:number):object return module.new(r,g,b,0)end
function from.color3(c:Color3,t:number):object return module.new(c.R,c.G,c.B,t)end

module.equals = function(self: object, a: object | any): boolean
	if typeof(a) ~= 'table'then return false;end
	return self.r == a.r and 
		self.g == a.g and 
		self.b == a.b and 
		self.t == a.t;
end

module.toString = function(self: object)return`{self.r},{self.g},{self.b},{self.t}`end

module.__tostring = module.toString
module.__eq = module.equals
module.__index = module
module.from = from

return module
