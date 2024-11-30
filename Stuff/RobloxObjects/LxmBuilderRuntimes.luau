local Objects = script.Parent
local LxmBuilder = require(Objects["@CHL/LxmBuilder"])
local Dash = require(Objects["@CHL/DashSingular"])
local AttributeBuilder = require(Objects["@CHL/AttributeBuilder"])
local TagS = require(Objects["@CHL/TagString"])

type ce_param = LxmBuilder.ce_param

local module = {}
local running_context = require(Objects["@CHL/RunningContext"])

RunService = game:GetService('RunService')
disguise = require(Objects.LuaUTypes).disguise

function move_factory(t)
	return function(from, to)
		t[to] = t[from]
		t[from] = nil
	end
end

function remove_factory(t)
	return function(...)
		Dash.forEachArgs(function(a)
			t[a] = nil
		end,...)
	end
end

module.game_runtime = {
	Instance = function(p: ce_param)
		local properties = p.virtual.Properties
		local inst = assert(p.instance)
		local remove = remove_factory(properties)

		-- attributes
		local map = AttributeBuilder.from.string(properties.AttributesSerialize)
		for i, v in map do
			if i:sub(1,3) == 'RBX' then
				continue
			end
			
			inst:SetAttribute(i, v)
		end
		remove'AttributesSerialize'

		-- tags
		local tags = TagS.from.string(properties.Tags)
		for v in tags do inst:AddTag(v) end
		remove(
			'Tags',

			'SourceAssetId','DefinesCapabilities'
		)

	end,
	Constraint = function(p: ce_param)
		p.object:add_to_lpq_by_virtual(p.virtual, 'Attachment0')
		p.object:add_to_lpq_by_virtual(p.virtual, 'Attachment1')
	end,
	Part = function(p: ce_param)move_factory(p.virtual.Properties)('shape', 'Shape')end,
	BasePart = function(p: ce_param)
		local bp = p.instance
		local prop = p.virtual.Properties
		local move = move_factory(prop)

		move('Color3uint8', 'Color')

		-- needs check
		remove_factory(prop)('MaterialVariantSerialized', 'formFactorRaw')

		move('Velocity','AssemblyLinearVelocity')
		move('RotVelocity', 'AssemblyAngularVelocity')
		move('size', 'Size')
	end,
	BodyPartDescription = function(p: ce_param)
		p.object:add_to_lpq_by_virtual(p.virtual, 'Instance')
	end,
	Humanoid = function(p: ce_param)
		local prop = p.virtual.Properties
		local move = move_factory(prop)
		
		remove_factory(prop)('CollisionType', 'InternalHeadScale', 'InternalBodyScale')
		move('Health_XML', 'Health')
	end,
	HumanoidDescription = function(p: ce_param)
		remove_factory(p.virtual.Properties)('EmotesDataInternal','EquippedEmotesDataInternal')
	end,
	Model = function(p:ce_param)
		p.object:add_to_lpq_by_virtual(p.virtual, 'PrimaryPart')
		
		remove_factory(p.virtual.Properties)(
			'ModelMeshCFrame', 
			'ModelMeshData', 
			'ModelMeshSize',
			'NeedsPivotMigration',
			'ScaleFactor',
			'WorldPivotData',
			'LevelOfDetail'
		)
	end,
	JointInstance = function(p:ce_param)
		p.object:add_to_lpq_by_virtual(p.virtual, 'Part0')
		p.object:add_to_lpq_by_virtual(p.virtual, 'Part1')
	end,
	MeshPart = function(p: ce_param)
		local prop = p.virtual.Properties
		local folder = assert(script:FindFirstChild('MeshParts'), 'Meshing issue: missing folder.')
		p.instance:Destroy()
		p.instance = disguise()

		for _, v in folder:GetChildren() do
			if v:IsA('MeshPart') and v.MeshId == prop.MeshId then
				p.instance = v:Clone()
				break
			end
		end

		assert(p.instance, 'MeshPart: .MeshId can\'t be used, no equivilent exists.')
		remove_factory(prop)(
			'MeshId',
			'AeroMeshData',
			'HasJointOffset',
			'HasSkinnedMesh',
			'InitialSize',
			'JointOffset',
			'PhysicalConfigData',
			'PhysicsData',
			'UnscaledCofm',
			'UnscaledVolInertiaDiags',
			'UnscaledVolume',
			'VertexCount',
			'RenderFidelity',
			'DoubleSided',
			'UnscaledVolInertiaOffDiags',
			'FluidFidelityInternal'
		)
	end,
}

local replacement = module[`{running_context}_runtime`]

if replacement then
	LxmBuilder.creation_exceptions = replacement
else
	warn(`missing running context case: {running_context}`)
end

return module
