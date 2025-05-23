local Objects = script.Parent
local Object = require('./Object')
local Class = require('./Class')

export type object = {
	vertices: {Vector3};
	normals: {Vector3};
	textures: {Vector2};
	faces: {face};
	
	get_center: (self: object) -> Vector3;
	to_output: (self: object) -> iterator;
	compress: (self: object) -> ();
} & Object.object_inheritance

export type face = {
	vertices: {number};
	normals: {number}?;
	textures: {number}?;
	referral: object;

	getOBJLineArgs: (self: face) -> string;
	getNormal: (self: face, j: number) -> Vector3;
	getTexture: (self: face, j: number) -> Vector2;
} & Object.object_inheritance

export type face_args = {
	vertices: {number};
	normals: {number}?;
	textures: {number}?
}

--##############################################################################
--##############################################################################
--##############################################################################

local Destructable = require('./@CHL>Destructable')
local module = {}

Face = {}
disguise = require('./LuaUTypes').disguise

function Face.new(o: object, args: face_args): face
	local self: face = Object.from.class(Face)
		
	self.vertices = args.vertices
	self.referral = o
	self.normals = args.normals
	self.textures = args.textures

	return self
end

function Face.getTexture(self: face, j: number)
	if not self.textures then return Vector2.yAxis end

	return self.referral.textures[self.textures[j]]
		
		--.referral.textures[self.textures[j]]
end

function Face.getOBJLineArgs(self: face)
	local s = ''

	for i = 1, 3 do
		if i ~= 1 then
			s ..= ' '
		end

		s ..= self.vertices[i]

		if self.textures then
			s ..= '/' .. self.textures[i]
		end

		if self.normals then
			if not self.textures then
				s ..= '/'
			end

			s ..= '/' .. self.normals[i]
		end

	end

	return s
end

function Face.getNormal(self: face, j: number)
	self:assertDestruction()

	local o = self.referral
	local n = self.normals

	if n then return o.normals[n[j]]end

	local v = self.vertices
	local w = o.vertices

	return (w[v[1]] - w[v[2]]):Cross(w[v[1]] - w[v[3]]).Unit
end

function Face.destroy(self: face)self.isDestroyed = true;self.referral = disguise();end

Face.Destroy = Face.destroy
Face.assertDestruction = Destructable.assertDestruction

Class.makeProperClass(Face, '@CHL>OBJ>Face')

module.face = Face

--##############################################################################
--##############################################################################
--##############################################################################

local Iterator = require('./@CHL>Iterator')

export type iterator = {
	referral: object;
	
	i: number;
	mode: number;
} & Iterator.object<string>

OutputIterator = {}

function OutputIterator.new(o: object)
	local self: iterator = Iterator.new():__inherit(OutputIterator)
	
	self.referral = o
	self.mode = 1
	self.i = 1
	
	return self
end

function OutputIterator.canProceed()return true end

function OutputIterator.proceed(self: iterator)
	local mode = self.mode
	local i = self.i
	local ref = self.referral
	
	if mode == 1 then -- vertices
		if not ref.vertices[i] then
			self.i = 1
			self.mode = 2
			return self:proceed()
		end
		
		local v3 = ref.vertices[i]
		
		self.i += 1
		return `v {v3.X} {v3.Y} {v3.Z}\n`
	elseif mode == 2 then -- normals
		if not ref.normals[i] then
			self.i = 1
			self.mode = 3
			return self:proceed()
		end
		
		local v3 = ref.normals[i]
		
		self.i += 1
		
		return `vn {v3.X} {v3.Y} {v3.Z}\n`
	elseif mode == 3 then -- textures
		if not ref.textures[i] then
			self.i = 1
			self.mode = 4
			return self:proceed()
		end
		
		local v2 = ref.textures[i]
		
		self.i += 1
		
		return `vt {v2.X} {v2.Y}\n`
	elseif mode == 4 then --  face
		if not ref.faces[i] then return end
		
		local face = ref.faces[i]
		
		self.i += 1
		
		return `f {face:getOBJLineArgs()}\n`
	end
end

Class.makeProperClass(OutputIterator, '@CHL>OBJ>OutputIterator')

--##############################################################################
--##############################################################################
--##############################################################################

local Map = require('./@CHL>Map')
local StringParser = require('./@CHL>StringParser')
local Dash = require('./@CHL>DashSingular')

type map<I, V> = Map.simple<I, V>
type dict<A> = Map.dictionary<A>

insert = table.insert
remove = table.remove
OBJ = {}
from = {}

function compressFromMap<A>(a: {A}, m: map<string, number>)
	local i, v, s = 1, nil

	while i <= #a do
		v = a[i]
		s = tostring(v)

		if not m[s] or m[s] < i then
			remove(a, i)
			continue
		elseif m[s] > i then
			m[s] = i
		end

		i += 1
	end
end

function getLineArgs(p: StringParser.object, n: number): {string}
	local result = {}
	local m = n

	while n > 1 do
		local s = p:pop_until' '
		assert(s, `Missing arg: {m - n + 1}/{m};\nStatus: {p.referral}`)

		insert(result, s)
		n -= 1
	end

	local s = p:pop_until('\n')

	insert(result, s)

	return result
end

function getNumberArgs(p: StringParser.object, n: number): {number}
	local r = getLineArgs(p, n)

	for i, v in next, r do
		r[i] = tonumber(v)
	end

	return (r)
end

function forwardSlashSplit(s: string): (...number)
	local r = s:split'/'

	for i, v in next, r do
		r[i] = tonumber(v)
	end

	return unpack(r)
end

function from.string_parser(parser: StringParser.object): object
	local self = OBJ.new()
	
	while not parser:is_at_end() do
		if parser:c_pop('v ', true) then
			local x, y, z = unpack(getNumberArgs(parser, 3))
			assert(x and y and z, parser:get_snapshot())

			insert(self.vertices, Vector3.new(x,y,z))
		elseif parser:c_pop('f ', true) then
			local a = getLineArgs(parser, 3)

			assert(a)

			local pa, na, ta = forwardSlashSplit(a[1])
			local pb, nb, tb = forwardSlashSplit(a[2])
			local pc, nc, tc = forwardSlashSplit(a[3])

			local args: face_args =  {
				vertices = {pa, pb, pc};
			}

			if na then
				args.normals = {na, nb, nc}
			end

			if ta then
				args.textures = {ta, tb, tc}
			end

			insert(self.faces, Face.new(self, args))
		elseif parser:c_pop('vn ', true) then
			local x, y, z = unpack(getNumberArgs(parser, 3))

			assert(x and y and z)

			insert(self.normals, Vector3.new(x, y, z))
		elseif parser:c_pop('vt ', true)then
			local x, y = unpack(getNumberArgs(parser, 2))

			assert(x and y)

			insert(self.textures, Vector2.new(x, y))
		elseif parser:c_pop('\n', true) then
		elseif parser:c_pop('o ', true)then parser:pop_until('\n')
		else
			error(`Unknown line: {parser:get_snapshot()}`)
		end
	end
	
	return self
end

-- warning: must be destroyed if completed
function OBJ.new(): object
	local self: object = Object.from.class(OBJ)

	self.vertices = {}
	self.faces = {}
	self.normals = {}
	self.textures = {}

	return self
end

function OBJ.compress(self: object)
	-- local vN, nN, tN = 0, 0, 0
	local vertexMap: dict<number> = {}
	local normalMap: dict<number> = {}
	local textureMap: dict<number> = {}

	for _, f in self.faces do
		for i = 1, 3 do
			local j = f.vertices[i]
			local v = self.vertices[j]
			local s = tostring(v)

			if not vertexMap[s] then vertexMap[s] = j end

			f.vertices[i] = s

			if f.normals then 
				j = f.normals[i]
				local n = self.normals[j]
				s = tostring(n)

				if not normalMap[s] then normalMap[s] = j end

				f.normals[i] = s

			end

			if not f.textures then continue end

			j = f.textures[i]
			local t = self.textures[j]
			s = tostring(t)

			if not textureMap[s] then textureMap[s] = j end

			f.textures[i] = s
		end
	end

	compressFromMap(self.vertices, vertexMap)
	compressFromMap(self.normals, normalMap)
	compressFromMap(self.textures, textureMap)

	for _, f in self.faces do
		for i = 1, 3 do
			f.vertices[i] = vertexMap[f.vertices[i]]

			if f.normals then
				f.normals[i] = normalMap[f.normals[i]]
			end

			if not f.textures then continue end

			f.textures[i] = textureMap[f.textures[i]]
		end
	end
end

function OBJ.destroy(self: object)
	for _, v in self.faces do
		v:destroy()
	end
end

function OBJ.to_output(self: object)return OutputIterator.new(self)end

function OBJ.get_center(self: object)
	return Dash.reduce(self.vertices,function(l,c)return l+c end, Vector3.zero) / #self.vertices
end

from.string = Dash.compose(StringParser.new,from.string_parser) :: (string)->object

OBJ.from = from
OBJ.Destroy = OBJ.destroy

Class.makeProperClass(OBJ, '@CHL>OBJ')

module.obj = OBJ

return module
