export type editableMesh = {
	GetUVs: (self: editableMesh)->{number};
	GetFaces: (self: editableMesh)->{number};
	GetColors: (self: editableMesh)->{number};
	GetFaceUVs: (self: editableMesh, face_id: number)->{number};
	GetNormals: (self: editableMesh)->{number};
	GetVertices: (self: editableMesh)->{number};
	GetFaceColors: (self: editableMesh, face_id: number)->{number};
	GetFaceNormals: (self: editableMesh, face_id: number)->{number};
	GetFaceVertices: (self: editableMesh, face_id: number)->{number};
	GetAdjacentFaces: (self: editableMesh, face_id: number)->{number};
	GetAdjacentVertices: (self: editableMesh, vertex_id: number)->{number};
	GetFacesWithAttribute: (self: editableMesh, at_id:number)->{number};
	GetVerticesWithAttribute: (self: editableMesh, at_id:number)->{number};
	
	SetFaceUVs: (self: editableMesh, face_id: number, uv_ids: {number})->();
	SetFaceColors: (self: editableMesh, face_id: number, color_ids: {number})->();
	SetFaceNormals: (self: editableMesh, face_id: number, normals_ids: {number})->();
	SetFaceVertices: (self: editableMesh, face_id: number, vertex_ids: {number})->();
	
	RemoveUnused: (self: editableMesh)->{number};
	RaycastLocal: (self: editableMesh, origin: Vector3, dir: Vector3)->(number?, Vector3, any);
	FindVerticesWithinSphere: (self: editableMesh) -> {number};
	
} & EditableMesh

local module = {}

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type to_string_args = {
	vertices: boolean?;
	uvs: boolean?;
	faces: boolean?;
}

function module.to_string(e: editableMesh, args: to_string_args): string
	local lines = {`EditableMesh 0x{tostring(e)}`}
	
	if args.vertices then
		insert(lines, 'Vertices:')
		for _, v in e:GetVertices() do
			insert(lines, `{tostring(v)} | {e:GetPosition(v)}`)
		end
	end

	if args.uvs then
		insert(lines, 'UVs:')
		for _, v in e:GetUVs() do
			insert(lines, `{tostring(v)} | {e:GetUV(v)}`)
		end
	end
	
	if args.faces then
		insert(lines, 'Faces:')
		for _, f in e:GetFaces() do
			local s = tostring(f)
			insert(lines, `{s} |`)
			
			local spaces = (' '):rep(#s)
			if args.vertices then
				insert(lines, `{spaces} | Vertices`)
				
				for _, v in e:GetFaceVertices(f) do
					insert(lines, `{spaces} | > {v} | {e:GetPosition(v)}`)
				end
			end
			
			if args.uvs then
				insert(lines, `{spaces} | UVs`)

				for _, v in e:GetFaceUVs(f) do
					insert(lines, `{spaces} | > {v} | {e:GetUV(v)}`)
				end
			end
		end
	end
	
	return table.concat(lines, '\n')
end

--##########################################################################################
--##########################################################################################
--##########################################################################################

local Objects = script.Parent
local Dash = require(Objects["@CHL/DashSingular"])
local OBJ = require(Objects["@CHL/OBJ"])

AssetService = game:GetService('AssetService')
from = {}
compose = Dash.compose
map = Dash.map

-- returns an EditableMesh based on the mesh content of the meshpart
function from.meshpart(m: MeshPart): editableMesh
	return from.content(m.MeshContent)
end

function from.content(c:Content): editableMesh
	assert(c.SourceType ~= Enum.ContentSourceType.None, 'content is nil.')
	return AssetService:CreateEditableMeshAsync(c)
end

function from.blank(): editableMesh return AssetService:CreateEditableMesh()end

-- possibly buggy because points are often recreated for faces, o:compress() is suggested
function from.obj(o: OBJ.object): editableMesh
	local result = from.blank()
	
	local vertices=map(o.vertices,function(a0)return result:AddVertex(a0) end)
	local uvs = map(o.textures, function(a0)return result:AddUV(a0)end)
	
	for _, f in o.faces do
		local vertex_ids = map(
			f.vertices, 
			function(a0: number, a1: number)return result:FindClosestVertex(o.vertices[a0])end
		)
		local face_id = result:AddTriangle(unpack(vertex_ids))
		local normal_id = result:AddNormal();
		result:SetFaceNormals(face_id, table.create(3, normal_id))
		
		if f.textures then
			result:SetFaceUVs(face_id, map(f.textures, function(a0)return uvs[a0]end))
		end
	end
	
	return result
end

from.asset_string = compose(Content.fromUri, from.content):: (string)->editableMesh

module.from = from

--##########################################################################################
--##########################################################################################
--##########################################################################################

to = {}

local Vector3Utils = require(Objects["@CHL/Vector3Utils"])
local Vector2Utils = require(Objects["@CHL/Vector2Utils"])

insert = table.insert

-- returns OBJ object
function to.OBJ(e: editableMesh): OBJ.object
	local result = OBJ.obj.new()
	
	local faces = e:GetFaces()
	local vertex_ids = {}
	local normal_ids = {}
	local texture_ids = {}
	local vertex_ids_len = 1
	local normal_ids_len = 1
	local texture_ids_len = 1
	
	for _, f in faces do
		local vertices = e:GetFaceVertices(f)
		local normals = e:GetFaceNormals(f)
		local textures = e:GetFaceUVs(f)
		
		for j, v in vertices do
			local v3 = e:GetPosition(v)
			local s = Vector3Utils.to_string(v3)
			
			local i = vertex_ids[s]
			
			if not i then
				i = vertex_ids_len
				vertex_ids_len += 1
				vertex_ids[s] = i
				
				insert(result.vertices, v3)
			end
			
			vertices[j] = i
		end
		
		--[[
		for j, v in normals do
			local v3 = e:GetNormal(v)

			local i = normal_ids[v3]

			if not i then
				i = normal_ids_len
				normal_ids_len += 1
				normal_ids[v3] = i

				insert(result.normals, v3)
			end
			
			normals[j] = i
		end
		--]]
		
		for j, v in textures do
			local v2 = e:GetUV(v)
			local s = Vector2Utils.to_string(v2)

			local i = texture_ids[s]

			if not i then
				i = texture_ids_len
				texture_ids_len += 1
				texture_ids[s] = i

				insert(result.textures, v2)
			end
			
			textures[j] = i
		end
		
		local args: OBJ.face_args = {vertices = vertices}
		
		--if #normals > 0 then args.normals = normals end
		if #textures > 0 then args.textures = textures end
		
		local face = OBJ.face.new(result, args)
		
		insert(result.faces, face)
	end
	
	return result
end

-- returns meshpart from editablemesh
function to.meshpart(e: editableMesh)
	return AssetService:CreateMeshPartAsync(Content.fromObject(e))
end

module.to = to

--##########################################################################################
--##########################################################################################
--##########################################################################################

return module
