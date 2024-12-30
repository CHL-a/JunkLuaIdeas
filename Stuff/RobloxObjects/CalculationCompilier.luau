local module = {}
local Objects = script.Parent
local Set = require(Objects["@CHL/Set"])
local StringParser = require(Objects["@CHL/StringParser"])

export type token_type = 'number' | 'operator' | 'eof'
export type token = {
	whitespace: string;
	value: string;
	_type: token_type;
}

disguise = require(Objects.LuaUTypes).disguise
lexer = {}
lexer.from = {}
lexer.specific_symbols = Set.simple.from.chars'+*/-()'

function lexer.from.string(s: string): {token}
	local result = {}
	local parser = StringParser.new(s)
	
	while true do
		local token: token = disguise{}
		table.insert(result, token)
		
		local whitespace_i_from = parser.i
		
		-- parse whitespace
		while not parser:is_at_end() do
			local c = parser:peek()
			
			if not c:match('%s') then break;end
			
			parser:pop()
		end
		
		local whitespace_i_to = parser.i - 1
		
		token.whitespace = parser:peek_back(whitespace_i_to - whitespace_i_from + 1)

		if parser:is_at_end() then
			token._type = 'eof'
		end
		
		-- parse value
		if token._type == 'eof' then 
			token.value = ''
			break;
		end
		
		local c = parser:peek()
		if lexer.specific_symbols[c] then
			token._type = 'operator'
			token.value = c
			parser:pop()
		elseif c:match('%d') or c =='.' then
			local used_dot = c == '.'
			token._type = 'number'
			
			local token_from = parser.i

			parser:pop()
			
			while true do
				c = parser:peek()
				local token_end = parser.i - 1
				local token_value = parser:peek_back(token_end - token_from + 1)
				
				if c == '.' then
					if not used_dot then
						used_dot = true
					else
						error(`lexer: using double dots: token={token_value}.`)
					end
				elseif c:lower() == 'e' then
					parser:pop()
					
					parser:c_pop('-', true)
					
					assert(
						parser:c_pop('%d'), 
						`bad token: expected digit, got: {token_value}{parser:peek()}`
					)
					
					while parser:c_pop('%d')do end
					token.value = parser:peek_back(parser.i - token_from)
					break
				else
					token.value = token_value
					break;
				end
				
				parser:pop()
			end
		else
			print(token)
			error(`Got bad token: token={c}`)
		end
		
	end
	
	return result
end

function lexer.test()
	-- print(lexer.from.string(" 0"))
	print(lexer.from.string(" 01.0. "))
end

module.lexer = lexer

--###################################################################################
--###################################################################################
--###################################################################################

-- ast

ast = {}

export type ast_node = {
	operands: {ast_node}
} & token

export type ASTBuilderV1 = {
	list: {token};
	i: number;
	
	peek: (self: ASTBuilderV1)->token;
	increment: (self: ASTBuilderV1)->();
	pop: (self: ASTBuilderV1)->token;

	get_value: (self: ASTBuilderV1)->ast_node;
	get_expression: (self: ASTBuilderV1, prior: number?)->ast_node;
}

ASTBuilderV1 = {}

ASTBuilderV1.precedence = {
	['+'] = 0;
	['-'] = 0;
	['*'] = 1;
	['/'] = 1;

}


function ASTBuilderV1.new(list: {token}): ASTBuilderV1
	local self: ASTBuilderV1 = disguise(setmetatable({}, ASTBuilderV1))
	self.list = list;
	self.i = 1
	
	return self
end

function ASTBuilderV1.peek(self: ASTBuilderV1)return self.list[self.i]end
function ASTBuilderV1.increment(self: ASTBuilderV1)self.i+=1 end
function ASTBuilderV1.pop(self: ASTBuilderV1)local t = self:peek()self:increment()return t end

function ASTBuilderV1.get_value(self: ASTBuilderV1)
	local t = disguise(self:pop()) :: ast_node
	
	if t._type == 'operator' then
		if  t.value == '-' then
			t.operands = {self:get_value()}
		elseif t.value == '(' then
			local expr = self:get_expression()
			self:increment()
			t.operands = {expr}
		else
			error('Got operator: expected ( or -, got: ' .. t.value)
		end
	end
	
	assert(t._type ~= 'eof', 'Attempting to get value from eof. Is malformed')
	
	return t
end

function ASTBuilderV1.get_expression(self: ASTBuilderV1, a_p: number?)
	local a_p = a_p or 0
	if a_p >= 2 then
		return self:get_value()
	end
	
	local left = self:get_expression(1 + a_p)
	
	local op: ast_node = disguise(self:peek())
	
	if op._type == 'eof' then return left end
	assert(op._type == 'operator', `Non operator: {op._type} from {op.value}`)
	
	local p = ASTBuilderV1.precedence[op.value]
	
	while p==a_p do
		self:increment()
		local right = self:get_expression(1 + a_p)
		op.operands = {left, right}
		left = op
		op = disguise(self:peek())
		p = ASTBuilderV1.precedence[op.value]
	end
	
	return left
	
	-- print(self)
	--error('whoops: ' .. p .. '| ' .. disguise(a_p))
end

ASTBuilderV1.__index = ASTBuilderV1

ast.ASTBuilderV1 = ASTBuilderV1

function ast.parse(list: {token})
	return ASTBuilderV1.new(list):get_expression()
end

module.ast = ast

--###################################################################################
--###################################################################################
--###################################################################################

-- calculation
local Dash = require(Objects["@CHL/DashSingular"])

calculation = {}
compose = Dash.compose

calculation.from = {}

function ast_recursive(ast: ast_node): number
	local operands = ast.operands
	
	local value = if ast._type == 'number' then 
			assert(tonumber(ast.value),`bad tonumber: {ast.value}`)
		elseif ast._type == 'operator' then
			if ast.value == '(' then ast_recursive(unpack(operands))
			elseif ast.value == '-' then
				if #operands == 1 then -ast_recursive(unpack(operands))
				else ast_recursive(operands[1])-ast_recursive(operands[2])
			elseif ast.value == '+' then ast_recursive(operands[1])+ast_recursive(operands[2])
			elseif ast.value == '*' then ast_recursive(operands[1])*ast_recursive(operands[2])
			elseif ast.value == '/' then ast_recursive(operands[1])/ast_recursive(operands[2])
			else nil
		else nil
		
	assert(value, 'no val')
	return value
end

calculation.from.ast_recursive = ast_recursive
calculation.from.token_list_recursive = compose(ast.parse, ast_recursive) :: ({token})->number
calculation.from.string_recursive = compose(
	lexer.from.string,
	calculation.from.token_list_recursive
) :: (string)->number;

module.calculation = calculation

return module
