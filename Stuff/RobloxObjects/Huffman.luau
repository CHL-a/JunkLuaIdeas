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

local Stack = require('./@CHL>LinkedStack')

export type base_code_struct<T> = {
	symbol: T;
	bit_length: number;
	code: number;
}

type to_huffman_table_struct<T> = {
	node: node<T>;
	bit_length: number;
	code: number;
}

function module.to_huffman_table<T>(root: node<T>): {base_code_struct<T>}
	local stack: Stack.object<to_huffman_table_struct<T>> = Stack.new()
	local result = {}
	
	stack:push({
		node = root;
		bit_length = 0;
		code = 0;
	})
	
	while not stack:is_empty() do
		local current = stack:pop()
		
		if current.node.has_value then
			table.insert(result, {
				symbol = current.node.value;
				bit_length = current.bit_length;
				code = current.code;
			})
		else
			stack:push({
				node = current.node.bit_1;
				bit_length = current.bit_length + 1;
				code = lshift(current.code, 1) + 1;
			})
			
			stack:push({
				node = current.node.bit_0;
				bit_length = current.bit_length + 1;
				code = lshift(current.code, 1);
			})
		end
	end
	
	return result
	
end

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

--[[
	Section: Canonical Huffman codes:
	
	Specifically, this itself has it's own algorithm, which is meant to improve compression, which takes in an array of numbers and transforms them back into actual
	huffman codes in a way that is optimal for compression, particularly when reconstructing it. this is because that array of numbers is deemed to be the huffman code 
	lengths (code length as apply placed)
	
	note: even if the compression then decompression produces different huffman codes compared with no change, the algorithm for huffman decompression is still about 
	the same
	
	see canonical huffman code algorithms
]]

--[[
	note: 
	 * symbol is deemed unique (particularly, due to decompression, it is redundant to harbor two huffman codes that refer to the same symbol)
	 * bit_length has been also assigned per symbol
	 * canonical_code is deemed to be the code that is produced after the decompression algorithm is ran
]]
export type code_struct<T> = {
	canonical_code: number;
} & base_code_struct<T>

lshift = bit32.lshift
canonical = {}

--[[
	while code_struct is genericized, the default comparison operator is typically reserved for numbers, this function is subject to change
	
	procedure:
	 1. sort by symbol
	 2. for all symbols, in order of o:
	   * if o = 0, then the canonical_code is 0
	   * else, canonical_code is deemed to be previous_canonical_code + 1
	     * if the bit_length is different of the previous then the current canonical_code is left-shifted by the difference in bit length
]]
function canonical.decompress<T>(code_length_array: {code_struct<T>})
	table.sort(code_length_array, function(a, b)
		return a.bit_length < b.bit_length or (a.bit_length == b.bit_length and a.symbol < b.symbol)
	end)
	
	local n = #code_length_array
	
	code_length_array[1].canonical_code = 0
	
	for i = 2, n do
		local previous = code_length_array[i - 1]
		local current = code_length_array[i]
		
		current.canonical_code = previous.canonical_code + 1
		
		if current.bit_length ~= previous.bit_length then -- case where the bit length is different
			for j = previous.bit_length + 1, current.bit_length do
				current.canonical_code = lshift(current.canonical_code, 1)
			end
		end
	end
end

function canonical.compress<T>(base_code_struct_array: {base_code_struct<T>})
	table.sort(base_code_struct_array, function(a, b)
		return a.bit_length < b.bit_length or (a.bit_length == b.bit_length and a.symbol < b.symbol)
	end)
	
	for i, v in base_code_struct_array do
		local code
		
		if i == 1 then
			code = 0
		else
			local previous = base_code_struct_array[i - 1]
			
			code = previous.canonical_code + 1
			
			for j = previous.bit_length + 1, v.bit_length do
				code = lshift(code, 1)
			end
		end
		
		v.canonical_code = code
		v.code = code
	end
end

module.canonical = canonical

--############################################################################################################################################################################
--############################################################################################################################################################################
--############################################################################################################################################################################

return module
