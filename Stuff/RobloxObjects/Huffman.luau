--[[
	https://cmps-people.ok.ubc.ca/ylucet/DS/Huffman.html
	
	A frequency based tree where it is deemed to be an optimized verion of a binary tree.
	
	because a huffman tree's leaf nodes are based on the traversal of a path, typically binary, they must be deemed a full tree
]]

local module = {}

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

local LinkedStack = require('./@CHL>LinkedStack')

export type node<T> = {
	bit_0: node<T>;
	bit_1: node<T>;
	value: T;
	amount: number;
	has_value: boolean;
}

function module.is_full<T>(root: node<T>): boolean
	local result = true
	
	local stack: LinkedStack.object<node<T>> = LinkedStack.new()
	stack:push(root)
	
	while not stack:is_empty() do
		local node = stack:pop()
		
		if node.has_value then
			continue
		end
		
		if not node.bit_0 or
			not node.bit_1 then
			result = false
			break
		end
		
		stack:push(node.bit_0)
		stack:push(node.bit_1)
	end
	
	return result
end


--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

local Iterator = require('./@CHL>Iterator')
local Object = require('./Object')
local Class = require('./Class')
local Map = require('./@CHL>Map')

export type map<I, V> = Map.simple<I, V>

export type tree_builder<T> = {
	nodes: {node<T>};
	
	all: (self: tree_builder<T>) -> node<T>;
} & Iterator.simple<node<T>>

--Dash.promise:await()
tree_builder = {}
tree_builder.from = {}

function tree_builder.new<T>(nodes: {node<T>}): tree_builder<T>
	local self: tree_builder<T> = Object.simple.new(tree_builder)
	
	self.nodes = nodes
	
	return self
end

function tree_builder.can_proceed<T>(self: tree_builder<T>)
	return #self.nodes > 1 
end

function tree_builder.proceed<T>(self: tree_builder<T>): node<T>
	if not self:can_proceed() then return; end
	
	local nodes = self.nodes
	
	local least = 1
	local almost_least = 2
	
	if nodes[least].amount > nodes[almost_least].amount then
		least = 2
		almost_least = 1
	end
	
	local n = #nodes
	
	for i = 3, n do
		local node = nodes[i]
		
		if node.amount > nodes[almost_least].amount then
			continue
		end
		
		if node.amount < nodes[least].amount then
			almost_least = least
			least = i
		else
			almost_least = i
		end
	end
	
	local node: node<T> = {}
	node.bit_0 = nodes[least]
	node.bit_1 = nodes[almost_least]
	node.amount = node.bit_0.amount + node.bit_1.amount
	
	table.remove(nodes, math.max(least, almost_least))
	table.remove(nodes, math.min(least, almost_least))
	table.insert(nodes, node)
	
	return node
end

function tree_builder.all<T>(self: tree_builder<T>): node<T>
	while self:can_proceed() do
		self:proceed()
	end
	
	return self.nodes[1]
end

function tree_builder.from.frequency_map<T>(freq_map: map<T, number>): tree_builder<T>
	local nodes: {node<T>} = {}
	
	for key, val in freq_map do
		table.insert(nodes, {
			amount = val;
			value = key;
			has_value = true
		})
	end
	
	return tree_builder.new(nodes)
end

Class.make_proper_class(tree_builder, '@CHL>Huffman>tree_builder')

module.tree_builder = tree_builder

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

export type traverser<T> = {
	current: node<T>;
	traverse: (self: traverser<T>, bit: number) -> ();
	all: (self: traverser<T>, bits: {number}) -> ();
}

traverser = {}

function traverser.new<T>(root: node<T>): traverser<T>
	local self: traverser<T> = Object.simple.new(traverser)
	
	self.current = root
	
	return self
end

function traverser.traverse<T>(self: traverser<T>, bit: number)
	local current = self.current
	
	assert(not math.isinf(bit), 'bit is inf')
	assert(bit * bit == bit, 'bit is not binary')
	
	self.current = current[`bit_{bit}`]
end

function traverser.all<T>(self: traverser<T>, bits: {number})
	for _, bit in bits do
		self:traverse(bit)
	end
end

Class.make_proper_class(traverser, '@CHL>Huffman>traverser')

module.traverser = traverser

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

export type branch_builder<T> = {
	root: node<T>;
	grow: (self: branch_builder<T>, value: T, num: number, bits_amount: number) -> ();
}

branch_builder = {}

function branch_builder.new<T>(root: node<T>): branch_builder<T>
	local self: branch_builder<T> = Object.simple.new(branch_builder)
	
	self.root = root
	
	return self
end

function branch_builder.grow<T>(self: branch_builder<T>, value: T, num: number, bits_amount: number)
	local current: node<T> = self.root
	
	for i = 1, bits_amount do
		local j = bits_amount - i
		local x = bit32.rshift(num, j)
		local bit = bit32.band(x, 1)
		
		if not current[`bit_{bit}`] then
			current[`bit_{bit}`] = {}
		end
		
		current = current[`bit_{bit}`]
		
		if current.has_value then
			print(value, current, self.root)
			
			error(`collision met: num={num}, bits_amount={bits_amount}`)
		end
	end
	
	current.value = value
	current.has_value = true
end

Class.make_proper_class(branch_builder, '@CHL>Huffman>branch_builder')

module.branch_builder = branch_builder

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

export type length_value_map<T> = Map.dictionary<T>

local Dash = require('./@roblox>Dash')

length_value_map = {}
length_value_map.from = {}
Dash.promise:await()
last = Dash.last

function length_value_map.from.huffman_tree<T>(root: node<T>): length_value_map<T>
	local stack = {0}
	local traverser_0 = traverser.new(root)
	local result = {}
	
	while #stack > 0 do
		traverser_0:all(stack)
		
		local current: node<T> = traverser_0.current
		
		if not current then
			continue
		end
		
		if not current.has_value then
			table.insert(stack, 0)
		else
			local length = #stack
			local value = 0
			
			for i = 1, #stack do
				value = value * 2 + stack[i]
			end
			
			local index = `{length},{value}`
			
			result[index] = current.value
			
			while last(stack) == 1 do
				table.remove(stack)
			end
			
			if #stack > 0 then
				stack[#stack] = 1
			end
		end
		
		traverser_0.current = root
	end
	
	return result
end

module.length_value_map = length_value_map

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

return module
