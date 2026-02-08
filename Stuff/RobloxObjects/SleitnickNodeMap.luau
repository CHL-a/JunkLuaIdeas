local module = {}

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type node = {
	position: Vector3;
	connections: {node};
}

node = {}

function node.new(position: Vector3): node
	local self: node = {}
	self.position = position
	self.connections = {}
	return self
end

module.node = node

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type graph = {
	nodes: {node};
}

graph = {}
tinsert = table.insert

function graph.from_instance(folder: Folder): graph
	local result: graph = {}
	local map = {}
	
	result.nodes = {}
	
	for _, vector3_value: Vector3Value in folder:GetChildren() do
		if not vector3_value:IsA('Vector3Value') then continue end

		local node = node.new(vector3_value.Value)
		
		map[vector3_value] = node
		tinsert(result.nodes, node)
	end
	
	for instance, node: node in map do
		for _, object_value: ObjectValue in instance:GetChildren() do
			if not object_value:IsA('ObjectValue') then continue end
			
			local other = map[object_value.Value]
			
			tinsert(node.connections, other)
		end
	end
	
	table.clear(map)
	
	return result
end


module.graph = graph

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

return module
