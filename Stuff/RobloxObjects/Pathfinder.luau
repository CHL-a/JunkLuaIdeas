local module = {}

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Map = require('./@CHL>Map')
local GlobalAttachmentHolder = require('./@CHL>GlobalAttachmentHolder')
local InstanceUtils = require('./@CHL>InstanceUtils')

type dict<T> = Map.dictionary<T>

export type create_path_arg = {
	AgentRadius: number?;
	AgentHeight: number?;
	AgentCanJump: boolean?;
	AgentCanClimb: boolean?;
	WaypointSpacing: number?;
	-- i presume that this stores strings of material names and pathfindermodifier labels
	Costs: dict<number>?;
}

path_finding_service = game:GetService('PathfindingService')

default = {}

function default.create_path(arg: create_path_arg): Path
	return path_finding_service:CreatePath(arg)
end

default.link = {}

export type position = Attachment | CFrame | Vector3 | BasePart

function default.to_position(arg: position): Vector3
	local result

	if typeof(arg) == 'CFrame' then      result = arg.Position
	elseif typeof(arg) == 'Vector3' then result = arg
	elseif typeof(arg) == 'Instance' then
		if arg:IsA('BasePart') then
			result = arg.Position
		elseif arg:IsA('Attachment') then
			result = arg.WorldPosition
		end
	end

	return result
end

function default.to_attachment(arg: position): Attachment
	local result
	
	if typeof(arg) == 'CFrame' then      result = GlobalAttachmentHolder.place_cframe(arg)
	elseif typeof(arg) == 'Vector3' then result = GlobalAttachmentHolder.place_position(arg)
	elseif typeof(arg) == 'Instance' then
		if arg:IsA('BasePart') then
			result = GlobalAttachmentHolder.place_cframe(arg.CFrame)
		elseif arg:IsA('Attachment') then
			result = arg
		else
			error(`{arg.ClassName} cannot be converted to an attachment.`)
		end
	end
	
	return result
end

function default.link.new(from: position, to: position, label: string?, is_bidirectional: boolean?): PathfindingLink
	local result = Instance.new('PathfindingLink')
	result.Attachment0 = default.to_attachment(from)
	result.Attachment1 = default.to_attachment(to)
	result.IsBidirectional = not not is_bidirectional
	
	if label then result.Label = label end
	
	result.Parent = GlobalAttachmentHolder.get_holder()
	
	return result
end

function default.link.walk(from: position, to: position, is_bidirectional: boolean?): PathfindingLink return default.link.new(from, to, 'walk', is_bidirectional)end
function default.link.jump(from: position, to: position, is_bidirectional: boolean?): PathfindingLink return default.link.new(from, to, 'Jump', is_bidirectional ~= false)end
function default.link.warp(from: position, to: position, is_bidirectional: boolean?): PathfindingLink return default.link.new(from, to, 'warp', is_bidirectional)end

function default.get_node_folder():Folder return InstanceUtils.get_or_create(workspace, '__pathfinder_node_folder', 'Folder')end

function default.get_node_visual(position: position?): Part
	local result = Instance.new('Part')
	result.Shape = Enum.PartType.Ball
	
	if position then
		result.Position = default.to_position(position)
	end
	
	result.Transparency = .5
	result.Anchored = true
	result.CanCollide = false
	result.CanQuery = false
	result.Size = Vector3.one
	result.Color = Color3.new(1)
	
	return result
end

function default.view_nodes(points: {PathWaypoint}, do_clear: boolean?)
	local node_folder = default.get_node_folder()
	
	if do_clear then
		node_folder:ClearAllChildren()
	end
	
	for _, v in points do
		local visual = default.get_node_visual(v.Position)
		visual.Parent = node_folder
	end
end

default.service = path_finding_service
module.default = default

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- below is incomplete
export type node_type = 'walk' | 'climb' | 'jump'

export type node = {
	visible: boolean,
	neighbors: {edge},
	position: Vector3,
	type: node_type,
	part_visual: Part?;

	toggle_visibility: (self: node, is_visible: boolean) -> ();
	is_neighbor: (self: node, other: node)-> boolean;
	get_edge_from_neighbor: (self: node, other: node) -> edge?;
}

local Class = require('./Class')
local Object = require('./Object')

node = {}

function node.new(): node
	local self: node = Object.simple.new(node)
	
	self.visible = false
	self.position = Vector3.zero
	self.type = 'walk'
	self.neighbors = {}
	
	return self
end

function node.toggle_visibility(self: node, is_visible: boolean)
	self.visible = is_visible
	
	if not self.part_visual then
		return
	end
	
	self.part_visual.Position = self.position
	self.part_visual.Transparency = is_visible and .5 or 1
end

function node.is_neighbor(self: node, other: node): boolean
	for _, edge: edge in self.neighbors do
		if edge:get_other_node(self) == other then
			return true
		end
	end
	
	return false
end

function node.get_edge_from_neighbor(self: node, other: node): edge?
	for _, edge: edge in self.neighbors do
		if edge:get_other_node(self) == other then
			return edge
		end
	end
end

Class.make_proper_class(node, '@CHL>Pathfinder>Node')

module.node = node

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type edge = {
	node_1: node;
	node_2: node;
	cost_1: number;
	cost_2: number;
	waypoints_1: {PathWaypoint};
	waypoints_2: {PathWaypoint};
	visible: boolean;
	part_visual: Part?;

	toggle_visibility: (self: edge, is_visible: boolean) -> ();
	get_end_index: (self: edge, node: node)->number;
	get_other_node: (self: edge, node: node)->node?;
	has_nodes: (self: edge)->boolean;
	
	-- does a refresh or an assignment to the cost in terms of studs distance and waypoints
	compute_path_async: (self: edge, path: Path, start_at: node)->();
	get_cost: (self: edge, finish_at: node)->number;
	get_waypoints: (self: edge, finish_at: node)->{PathWaypoint};
}

edge = {}

function edge.new(): edge return Object.simple.new(edge) end
function edge.has_nodes(self: edge)return self.node_1 and self.node_2 end

function edge.get_other_node(self: edge, node: node): node
	if self.node_1 == node then return self.node_2 end
	if self.node_2 == node then return self.node_1 end
end

function edge.get_end_index(self: edge, node: node): number
	if node == self.node_1 then
		return 1
	else
		return 2
	end
end

function edge.compute_path_async(self: edge, path: Path, start_at: node): ()
	local end_index = self:get_end_index(start_at)
	local other = self:get_other_node(start_at)
	local waypoints: {PathWaypoint}
	local cost
	
	path:ComputeAsync(start_at.position, other.position)
	
	waypoints = path:GetWaypoints()
	
	self[`waypoints_{end_index}`] = waypoints
	
	if #waypoints == 0 then return end
	
	cost = 0
	
	local previous = waypoints[1]
	
	for i = 2, #waypoints do
		local waypoint = waypoints[i]
		local distance = (waypoint.Position - previous.Position).Magnitude
		cost += distance
		previous = waypoint
	end
	
	self[`cost_{end_index}`] = cost
end

function edge.get_cost(self: edge, finish_at: node): number
	local node = self:get_other_node(finish_at)
	local end_index = self:get_end_index(node)
	return self[`cost_{end_index}`]
end

function edge.get_waypoints(self: edge, finish_at: node): {PathWaypoint}
	local node = self:get_other_node(finish_at)
	local end_index = self:get_end_index(node)
	return self[`waypoints_{end_index}`]
end

function edge.toggle_visibility(self: edge, is_visible: boolean)
	self.visible = is_visible
	
	if self.part_visual then
		local diff = self.node_1.position - self.node_2.position
		
		local expected_size = Vector3.new(diff.Magnitude, 1, 1)
		local expected_middle = (self.node_1.position + self.node_2.position) / 2
		local expected_cframe = CFrame.lookAt(expected_middle, self.node_2.position) * CFrame.Angles(0, math.pi/2, 0)
		
		self.part_visual.Size = expected_size
		self.part_visual.CFrame = expected_cframe
		self.part_visual.Transparency = is_visible and 0.5 or 1
	end
end

Class.make_proper_class(edge, '@CHL>Pathfinder>Edge')

module.edge = edge

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type graph = {
	nodes: {node};
	
	closest_node: (self: graph, position: Vector3)->();
	add_node_from_position: (self: graph, position: Vector3)->node;
	get_node_from_position: (self: graph, position: Vector3)->node?;
	
	connect_node: (self: graph, node_1: node, node_2: node)->edge;
}

graph = {}

function graph.new(nodes: {node}): graph
	local self: graph = Object.simple.new(graph)
	
	self.nodes = nodes
	
	return self
end

function graph.closest_node(self: graph, position: Vector3): node
	local small
	local result
	
	for _, node in self.nodes do
		local distance = (position - node.position).Magnitude
		if not result or distance < small then
			result = node
			small = distance
		end
	end
	
	return result
end

function graph.add_node_from_position(self: graph, position: Vector3): node
	local node = node.new()
	
	node.type = 'walk'
	node.position = position
	
	tinsert(self.nodes, node)
	
	return node
end

function graph.get_node_from_position(self: graph, position: Vector3): node
	local closest, small
	
	if #self.nodes == 0 then return end
	
	closest = self.nodes[1]
	small = (position - closest.position).Magnitude
	
	for i = 2, #self.nodes do
		local node = self.nodes[i]
		local distance = (position - node.position).Magnitude
		
		if distance < small then
			closest = node
			small = distance
		end
	end
	
	return closest
end

function graph.connect_node(self: graph, node_1: node, node_2: node): edge
	if node_1:is_neighbor(node_2) then return end
	
	local edge = edge.new()
	
	edge.node_1 = node_1
	edge.node_2 = node_2
	
	tinsert(node_1.neighbors, edge)
	tinsert(node_2.neighbors, edge)
	
	return edge
end

Class.make_proper_class(graph, '@CHL>Pathfinder>Graph')

module.graph = graph

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Set = require('./@CHL>Set')
-- attempts to use a hierarchal graph path finder approach to allow scalability

type set<T> = Set.simple<T>

export type finder = {
	graph: graph;
	path: Path;
	
	-- subject to change for a linked list
	traversal_high: {node};
	traversal_low: {PathWaypoint};
	
	accessable: {node};
	accessed: set<node>;
	heuristic: ((self: finder, node: node)->number)?;
	
	-- on higher node level, will assign traversal to be a list of high nodes
	compute_node_path: (self: finder, start: node, goal: node) -> ();
	compute_waypoint_path: (self: finder, start: node, goal: node) -> ();
	compute_waypoint_path_from_position: (self: finder, start: Vector3, goal: Vector3) -> ();
}


tinsert = table.insert
tclear = table.clear
finder = {}

function finder.new(graph: graph, path: Path)
	local self: finder = Object.simple.new(finder)
	
	self.path = path
	self.graph = graph
	self.traversal_high = {}
	self.traversal_low = {}
	self.accessed = {}
	self.accessable = {}
	
	return self
end

function finder.compute_node_path(self: finder, start: node, goal: node)
	tclear(self.traversal_high)
	
	if start == goal then
		tinsert(self.traversal_high, goal)
		return
	end
	
	tclear(self.accessed)
	tclear(self.accessable)
	
	for _, v in self.graph.nodes do
		v.f = nil
		v.g = nil
		v.h = nil
		v.parent = nil
	end
	
	tinsert(self.accessable, start)
	
	start.f = 0
	start.g = 0
	
	while self.accessable[1] do
		local node = table.remove(self.accessable, 1)
		
		self.accessed[node] = true
		
		for _, edge in node.neighbors do
			local neighbor = edge:get_other_node(node)
			
			if neighbor == goal then
				edge:compute_path_async(self.path, node)
				goal.parent = node
				break
			elseif not self.accessed[neighbor] then
				edge:compute_path_async(self.path, node)
				
				local e_cost = edge:get_cost(neighbor)
				
				if not e_cost then
					warn('specific inaccessable edge')
					
					if edge.part_visual then
						edge.part_visual.Color = Color3.new(1,.5,0)
						edge:toggle_visibility(true)
					else
						print('no part visual')
					end
					
					continue
				end
				-- handle inaccessable case
				
				local g = node.g + e_cost
				local h = self.heuristic(self, neighbor)
				local f = g + h
				
				neighbor.f = f
				neighbor.g = g
				neighbor.h = h
				neighbor.parent = node
				
				tinsert(self.accessable, neighbor)
			end
		end
		
		if goal.parent then
			break
		end
		
		table.sort(self.accessable, function(value_a, value_b)
			return value_a.f < value_b.f
		end)
	end
	
	local current = goal
	
	while current do
		tinsert(self.traversal_high, 1, current)
		local previous = current
		current = current.parent
		previous.parent = nil
	end
end

function finder.compute_waypoint_path(self: finder, start: Vector3, goal: Vector3)
	self:compute_node_path(start, goal)
	
	local result = self.traversal_low
	local high_nodes = self.traversal_high
	
	tclear(result)
	
	for i = 2, #high_nodes do
		local previous = high_nodes[i - 1]
		local current = high_nodes[i]
		local edge = previous:get_edge_from_neighbor(current)
		local waypoints = edge:get_waypoints(current)
		
		if i == 2 then
			tinsert(result, waypoints[1])
		end
		
		for i = 2, #waypoints do
			tinsert(result, waypoints[i])
		end
	end
	
	return result
end

-- mind possibility that original path from start to goal might be smaller than larger path
function finder.compute_waypoint_path_from_position (self: finder, start: Vector3, goal: Vector3)
	local start_node = self.graph:get_node_from_position(start)
	local goal_node = self.graph:get_node_from_position(goal)
	
	local traversal_low = self.traversal_low
	
	self:compute_waypoint_path(start_node, goal_node)
	
	local path = self.path
	local waypoints;
	
	path:ComputeAsync(start, start_node.position)
	
	waypoints = path:GetWaypoints()
	
	for i = 2, #waypoints do
		tinsert(traversal_low, i - 1, waypoints[i - 1])
	end
	
	path:ComputeAsync(goal_node.position, goal)
	
	waypoints = path:GetWaypoints()
	
	for i = 2, #waypoints do
		tinsert(traversal_low, waypoints[i])
	end
	
	return traversal_low
end

function finder.heuristic(self: finder, node: node): number return 0 end

Class.make_proper_class(finder, '@CHL>Pathfinder>Finder')

module.finder = finder

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
