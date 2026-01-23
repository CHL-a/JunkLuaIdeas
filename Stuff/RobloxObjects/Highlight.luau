local TableUtils = require('./@CHL>TableUtils')

local module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- section dedicated for allocating highlights

disguise = require('./LuaUTypes').disguise

module.population = 0
module.objects = {}

function module.can_register(): boolean
	return module.population < 31
end

function module.register(): Highlight
	if not module.can_register() then
		warn('Attempting to register too many highlights')
		return disguise()
	end

	module.population += 1

	local result = Instance.new('Highlight', script)

	module.objects[module.population] = result

	return result
end

export type query = {
	FillColor: Color3?;
	FillTransparency: number?;
	OutlineColor: Color3?;
	OutlineTransparency: number?;
	Adornee: Instance?;
	DepthMode: Enum.HighlightDepthMode?;
}

function module.find(q: query): {Highlight}
	local result = table.clone(module.objects)

	for i, v in q do
		if not v then continue end

		local j = 1

		while j <= #result do
			if result[j][i] ~= v then
				table.remove(result, j)
				continue
			end

			j+=1
		end
	end

	return result
end

--[[
	Notes: Returns
		1. Highlight, always returned but may not follow query
		2. bool, always returned, denotes does_follows_query
		3. int, may not be returned, denotes how many follows query
--]]
function module.get_or_create(q: query): (Highlight, boolean, number?)
	local found = module.find(q)
	local result = found[1]

	if result then
		return result, true, #found
	elseif module.can_register() then
		result = module.register()

		TableUtils.imprint(result, q, true)

		return result, true
	else
		return module.objects[1], false
	end
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- idea for groups:
--[[
	Group definition: In order to store highlights more efficiently one highlight can be created but is placed under a group so
	multiple parts can have their highlights rendered
	
	Group (Model)
		Highlight
		Humanoid
]]

local InstanceUtils = require('./@CHL>InstanceUtils')

export type group = Model & {
	Humanoid: Humanoid;
}

Group = {}

function Group.get_default_parent(): Folder
	if Group.default_parent then
		return Group.default_parent
	end
	
	local result = InstanceUtils.get_or_create(workspace, 'HighlightGroups', 'Folder')
	
	Group.default_parent = result
	
	return result
end

function Group.new(parent: Instance?): group
	parent = parent or Group.get_default_parent()
	
	local self = Instance.new('Model')
	local humanoid = Instance.new('Humanoid')
	
	humanoid.Parent = self
	self.Parent = parent
	
	self:AddTag('__is_highlight_group')
	
	return self
end

function Group.from_highlight(highlight: Highlight, parent: Instance?): group
	local self = Group.new(parent)
	
	highlight.Parent = self
	
	return self
end

function Group.get_highlight(group: group): Highlight
	assert(group:FindFirstChildWhichIsA('Highlight'))
end

module.group = Group

return module
