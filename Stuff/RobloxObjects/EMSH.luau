--##########################################################################################
--##########################################################################################
--##########################################################################################
--[[
	File Format:
	
	Notes: 
	 * Size is in bytes
	
	 * For all versions:
	|---------|----|---------------|------------------------------------------|
	|Name     |Size|Type           |Description                               |
	|---------|----|---------------|------------------------------------------|
	|Signature|4   |Literal        |Always "EMSH"                             |
	|Version  |4   |String         |Always "v", then three digits             |
	|---------|----|---------------|------------------------------------------|
	
	 * For Version v001:
	   * All little endian, for each data type
	|-------------|----|-------------------|------------------------------------------|
	|Name         |Size|Type               |Description                               |
	|-------------|----|-------------------|------------------------------------------|
	|Vertex #     |4   |UInt               |Represents # of vertices, or variable 'a' |
	|Vertex data  |12a |Vector3 (3xFloat32)|Represents Vertex position                |
	|UV #         |4   |UInt               |Represents # of UVs, or variable 'b'      |
	|UV data      |8b  |Vector2 (2xFloat32)|Represents UV data                        |
	|Color3a #    |4   |UInt               |Represents # of Color3a's, or variable 'c'|
	|Color3a data |4c  |Color3a (4xbytes)  |Represents Color3a data, 3 bytes for      |
	|             |    |                   |Color3, one byte for transparency/alpha   |
	|Triangle #   |4   |UInt               |Represents # triangles, or variable 'd'   |
	|Triangle Data|de  |UInt (dexUInt32)   |Represents triangle data, the size of each|
	|             |    |                   |element or 'e' varies because of the      |
	|             |    |                   |presence of b and c, e is 3 and increases |
	|             |    |                   |by 3 if b > 0 and 1 if c > 0.             |
	|             |    |                   |                                          |
	|             |    |                   |in v001, e is a constant 7 irregardless   |
	|             |    |                   |of b and c                                |
	|             |    |                   |                                          |
	|             |    |                   |Each UInt32 is 0-based indices            |
	|-------------|----|-------------------|------------------------------------------|
	
	 * For Version v002, e is inconstant, which implies that b and c may be zero
	   * For b to be zero, the mesh must own all UVs as Vector2.zero
	   * For c to be zero, the mesh must own all C3as as Pure white, or 
	     fromRGB(255,255,255), and alpha of 1
	
--]]
--##########################################################################################
--##########################################################################################
--##########################################################################################

local module = {}

local Objects = script.Parent
local EditableMesh = require(Objects["@CHL/EditableMesh"])
local BufferWrapper = require(Objects["@CHL/BufferWrapper"])
local Map = require(Objects["@CHL/Map"])

export type mesh = EditableMesh.editableMesh

--##########################################################################################
--##########################################################################################
--##########################################################################################

type map<I,V> = Map.simple<I,V>
type bufferw = BufferWrapper.object
type stream = BufferWrapper.stream

local Dash = require(Objects["@CHL/DashSingular"])

map = Dash.map
collect = Dash.collect
temp = BufferWrapper.getTemp()
insert = table.insert
v001 = {}

v001.from = {}
v001.to = {}

function v001.from.get_alt_map(array: {number}): (map<number, number>, number)
	return collect(array, function(a0: number, a1: number)return a1, a0-1 end), #array
end

function v001.from.map_transform(old, ref)
	return map(old, function(a0)return ref[a0]end)
end

function v001.from.e_mesh(mesh: mesh): bufferw
	local v_map, v_n = v001.from.get_alt_map(mesh:GetVertices())
	local uv_map, uv_n = v001.from.get_alt_map(mesh:GetUVs())
	local c3a_map, c3a_n = v001.from.get_alt_map(mesh:GetColors())
	
	local faces = mesh:GetFaces()
	
	local result = BufferWrapper.from.size(4 * (6 + 3*v_n + 2*uv_n + c3a_n + 7*#faces))
	local stream = BufferWrapper.Stream.new(result)
	
	stream:writestring('EMSHv001')
	
	-- vertices
	stream:writeu32(v_n)
	
	for id in v_map do
		local v3 = mesh:GetPosition(id)
		stream:writeFloat(v3.X)
		stream:writeFloat(v3.Y)
		stream:writeFloat(v3.Z)
	end
	
	-- uvs
	stream:writeu32(uv_n)
	
	for id in uv_map do
		local v2 = mesh:GetUV(id)
		stream:writeFloat(v2.X)
		stream:writeFloat(v2.Y)
	end
	
	-- color3as
	stream:writeu32(c3a_n)
	
	for id in c3a_map do
		local c3 = mesh:GetColor(id) or Color3.new(1,1,1)
		local a = mesh:GetColorAlpha(id) or 1

		stream:writeBytes(c3.R * 255, c3.G * 255, c3.B * 255, a * 255)
	end
	
	-- faces
	stream:writeu32(#faces)
	
	for _, f in faces do
		local f_vertices = v001.from.map_transform(mesh:GetFaceVertices(f), v_map)
		local f_uvs = v001.from.map_transform(mesh:GetFaceUVs(f), uv_map)
		local f_c3as = v001.from.map_transform(mesh:GetFaceColors(f), c3a_map)
			
		-- f_v
		stream:writeu32(f_vertices[1])
		stream:writeu32(f_vertices[2])
		stream:writeu32(f_vertices[3])
		
		-- f_u
		stream:writeu32(f_uvs[1])
		stream:writeu32(f_uvs[2])
		stream:writeu32(f_uvs[3])
		
		-- f_c
		stream:writeu32(f_c3as[1])
	end
	
	return result
end

function v001.to.check_header(stream: stream, ver: string)
	local primary = stream:readstring(4)
	assert(primary == 'EMSH', `Header issue: expected 'EMSH', got '{primary}'`)
	
	local vers = stream:readstring(4)
	assert(vers == `v{ver}`)
end

function v001.to.get_vertices_array(stream: stream, result: mesh): {number}
	local vn = stream:readu32()
	local vertices = {}
	for i = 1, vn do
		local x, y, z = stream:readFloat(), stream:readFloat(), stream:readFloat()
		insert(vertices, result:AddVertex(Vector3.new(x,y,z)))
	end
	
	return vertices
end

function v001.to.get_uv_array(stream: stream, result: mesh): {number}
	local un = stream:readu32()
	local uvs = {}
	for i = 1, un do
		local x, y = stream:readFloat(), stream:readFloat()
		insert(uvs, result:AddUV(Vector2.new(x,y)))
	end

	return uvs
end

function v001.to.get_c3a_array(stream: stream, result: mesh): {number}
	local c3an = stream:readu32()
	local c3as = {}
	for i = 1, c3an do
		local r,g,b,a = stream:readu8(), stream:readu8(), stream:readu8(), stream:readu8() / 255
		insert(c3as, result:AddColor(Color3.fromRGB(r,g,b), a))
	end

	return c3as
end

function v001.to.e_mesh(from: bufferw): mesh
	local result = EditableMesh.from.blank()
	local stream = BufferWrapper.Stream.new(from)
	
	v001.to.check_header(stream, '001')
	
	-- vertices
	local vertices = v001.to.get_vertices_array(stream, result)
	
	-- uvs
	local uvs = v001.to.get_uv_array(stream, result)
	
	-- c3as
	local c3as = v001.to.get_c3a_array(stream, result)
	
	-- faces
	local fn = stream:readu32()
	for i = 1, fn do
		local f_vs = map(
			{stream:readu32(),stream:readu32(),stream:readu32()}, 
			function(a0: number)return vertices[a0+1]end
		)
		local f1 = result:AddTriangle(unpack(f_vs))
		
		local f_us = map(
			{stream:readu32(),stream:readu32(),stream:readu32()},
			function(a0: number)return uvs[a0+1]end
		)
		
		result:SetFaceUVs(f1, f_us)
		
		local f_c = table.create(3, c3as[stream:readu32()+1])
		result:SetFaceColors(f1, f_c)
	end
	
	return result
end

module.v001 = v001

--##########################################################################################
--##########################################################################################
--##########################################################################################

clear = table.clear
find = Dash.find
v002 = {}

v002.from = {}
v002.to = {}

function v002.from.e_mesh(mesh: mesh): bufferw
	local v_map, v_n = v001.from.get_alt_map(mesh:GetVertices())
	local uv_map, uv_n = v001.from.get_alt_map(mesh:GetUVs())
	local c3a_map, c3a_n = v001.from.get_alt_map(mesh:GetColors())
	local face_size = 7
	
	-- check pre
	if not find(uv_map,function(_, a0)return mesh:GetUV(a0) ~= Vector2.zero end) then
		uv_n = 0
		clear(uv_map)
		face_size -= 3
	end
	
	if not find(c3a_map, function(_, a0)
			local a = mesh:GetColorAlpha(a0)
			local c3 = mesh:GetColor(a0)
			
			return c3.R * c3.G * c3.B * a ~= 1
		end)then
		clear(c3a_map)
		c3a_n = 0
		face_size -= 1
	end
	
	local faces = mesh:GetFaces()

	local result = BufferWrapper.from.size(4 * (6 + 3*v_n + 2*uv_n + c3a_n + face_size*#faces))
	local stream = BufferWrapper.Stream.new(result)

	stream:writestring('EMSHv002')

	-- vertices
	stream:writeu32(v_n)

	for id in v_map do
		local v3 = mesh:GetPosition(id)
		stream:writeFloat(v3.X)
		stream:writeFloat(v3.Y)
		stream:writeFloat(v3.Z)
	end

	-- uvs
	stream:writeu32(uv_n)

	for id in uv_map do
		local v2 = mesh:GetUV(id)
		stream:writeFloat(v2.X)
		stream:writeFloat(v2.Y)
	end

	-- color3as
	stream:writeu32(c3a_n)

	for id in c3a_map do
		local c3 = mesh:GetColor(id) or Color3.new(1,1,1)
		local a = mesh:GetColorAlpha(id) or 1

		stream:writeBytes(c3.R * 255, c3.G * 255, c3.B * 255, a * 255)
	end

	-- faces
	stream:writeu32(#faces)

	for _, f in faces do
		-- f_v
		local f_vertices = v001.from.map_transform(mesh:GetFaceVertices(f), v_map)

		stream:writeu32(f_vertices[1])
		stream:writeu32(f_vertices[2])
		stream:writeu32(f_vertices[3])

		-- f_u
		if uv_n > 0 then
			local f_uvs = v001.from.map_transform(mesh:GetFaceUVs(f), uv_map)

			stream:writeu32(f_uvs[1])
			stream:writeu32(f_uvs[2])
			stream:writeu32(f_uvs[3])
		end
		
		-- f_c
		if c3a_n > 0 then
			local f_c3as = v001.from.map_transform(mesh:GetFaceColors(f), c3a_map)
			stream:writeu32(f_c3as[1])
		end
	end

	return result
end

function v002.to.e_mesh(from: bufferw): mesh
	local result = EditableMesh.from.blank()
	local stream = BufferWrapper.Stream.new(from)

	v001.to.check_header(stream, '002')

	-- vertices
	local vertices = v001.to.get_vertices_array(stream, result)

	-- uvs
	local uvs = v001.to.get_uv_array(stream, result)

	-- c3as
	local c3as = v001.to.get_c3a_array(stream, result)

	-- faces
	local fn = stream:readu32()
	for i = 1, fn do
		local f_vs = map(
			{stream:readu32(),stream:readu32(),stream:readu32()}, 
			function(a0: number)return vertices[a0+1]end
		)
		local f1 = result:AddTriangle(unpack(f_vs))
		
		if #uvs > 0 then
			local f_us = map(
				{stream:readu32(),stream:readu32(),stream:readu32()},
				function(a0: number)return uvs[a0+1]end
			)

			result:SetFaceUVs(f1, f_us)
		end
		
		if #c3as > 0 then
			local f_c = table.create(3, c3as[stream:readu32()+1])
			result:SetFaceColors(f1, f_c)
		end
	end

	return result
end

module.v002 = v002

return module
