local StringParser = require('./@CHL>StringParser')
local Map = require('./@CHL>Map')

export type tag = {
	attributes : Map.dictionary<string>;
	tag : string;
	value : {tag | string}?;
	isEmpty: boolean?
}

local XML = {}
local parser = StringParser.new''

tinsert = table.insert
tremove = table.remove

XML.patterns = {}
XML.patterns.tag = '%w.:' -- atm it works for attributes as well
XML.patterns.attributeString = "'\""

XML.escapeSequences = {
	['&lt;']   = '<';
	['&gt;']   = '>';
	['&amp;']  = '&'; 
	['&apos;'] = '\'';
	['&quot;'] = '"';
}

-- tokenizer for XML
XML.tokenizer = {}
XML.tokenizer.queue = {}

function XML.tokenizer.push(whiteSpace, token, tkType)
	-- pre
	assert(type(whiteSpace) == 'string' and type(token) == 'string' and type(tkType) == 'string')
	
	-- main
	local struct : {
		whiteSpace: string;
		token: string;
		tkType: 'end' | 'tagEnd' | 'tagStart' | 'attributeIndex' | 'symbol' |
			'attributeValue' | 'emptyTagComplete' | 'tagComplete' | 'elementContent'
	} = {
		whiteSpace = whiteSpace;
		token = token;
		tkType = tkType
	}
	
	
	tinsert(XML.tokenizer.queue, struct)
end

function XML.tokenizer.peek(i)
	return XML.tokenizer.queue[i or 1]
end

function XML.tokenizer.pop()
	return tremove(XML.tokenizer.queue, 1)
end

function XML.tokenize_xml(s: string)
	-- pre
	assert(type(s) == 'string')
	
	-- main
	parser:reset(s)
	
	local isInTag = false

	local whiteSpace = ''
	
	while true do -- per token
		-- get whitespace
		while not parser:is_at_end() do
			
			if parser:peek_match('%s') then -- whitespace
				whiteSpace ..= parser:pop()
			elseif parser:peek_match('<!--') then -- comment
				local commentA, commentB = parser:pop_until('-->')
				whiteSpace ..= commentA .. commentB
			else -- none above
				break
			end
		end
		
		-- get token
		local token = ''
		local tkType
		
		if parser:is_at_end() then
			tkType = 'end'
		elseif parser:peek_match('<') and not parser:peek_match('<![CDATA[', true) then
			-- <
			token ..= parser:pop()
			
			-- / (if possible)
			if parser:peek_match('/') then
				tkType = 'tagEnd'
				token ..= parser:pop()
			else
				tkType = 'tagStart'
			end
			
			-- the tag
			token ..= parser:pop_until(`[^{XML.patterns.tag}]`)
			parser.i -= 1
			
			if tkType == 'tagStart' then
				isInTag = true
			end
		elseif isInTag then
			-- considered in tag: ex: attributes, "=", string values, etc
			
			local index = parser:peek_match((`[{XML.patterns.tag}]+`))
			local strDelim = parser:peek_match((`[{XML.patterns.attributeString}]`))
			
			if index then
				token = parser:pop(#index)
				tkType = 'attributeIndex'
			elseif parser:c_pop('=') then
				token = '='
				tkType = 'symbol'
			elseif strDelim then
				parser:pop()
				
				local content, strDelimB = parser:pop_until(`[{strDelim}]`)
				
				local value = strDelim .. content .. strDelimB
				
				local i = parser.i
				assert(XML.parse_string(value))
				parser.i = i
				parser.referral = s
				
				token = value
				tkType = 'attributeValue'
			elseif parser:peek_match('/>') or parser:peek_match('>') then
				isInTag = false
				continue
			else
				print(XML.tokenizer.queue)
				print(`undefined intag token: {parser:get_snapshot()}`)
				error(`undefined attribute token: |{parser:peek()}|`)
			end
		elseif parser:peek_match('/>') then
			token = parser:pop(2)
			tkType = 'emptyTagComplete'
		elseif parser:peek_match('>') then
			token = parser:pop()
			tkType = 'tagComplete'
		else
			-- considered in an element or something else, note how
			-- CDATA is more like a wrapper so their prefix and suffix will be 
			-- considered until parsing
			local content = ''
			local inCDATA = false
			
			while true do
				if parser:peek_match('<![CDATA[', true) then
					inCDATA = true
				elseif parser:peek_match(']]>', true) then
					inCDATA = false
				elseif not inCDATA and parser:peek_match('<') then
					break
				end
				
				content ..= parser:pop()
			end
			
			token = whiteSpace .. content
			whiteSpace = ''
			tkType = 'elementContent'
		end
		
		assert(token, 'no token:' .. parser:get_snapshot())
		assert(tkType, `undefined tk type: {token}{parser:get_snapshot()}`)
		
		XML.tokenizer.push(whiteSpace, token, tkType)
		
		whiteSpace = ''
		
		if tkType == 'end' then break end
	end
end

function XML.minify(s: string)
	-- pre
	assert(type(s) == 'string')
	
	-- main
	XML.tokenize_xml(s)
	
	local result = ''
	
	while true do
		local tkStruct = XML.tokenizer.pop()
		
		if tkStruct.tkType == 'end' then
			break
		elseif tkStruct.tkType == 'attributeIndex' then
			tkStruct.whiteSpace = ' '
		else
			tkStruct.whiteSpace = ''
		end
		
		result ..= tkStruct.whiteSpace .. tkStruct.token
	end
	
	return result
end

function XML.parse_cdata(s: string)
	parser:reset(s)

	assert(parser:c_pop('<![CDATA[', true), 'improper cdata')
	
	local result, suffix = parser:pop_until(']]>', true)
	print(`met |{s}|{result}|{suffix}`)
	assert(suffix, 'no suffix met')
	
	return result
end

function XML.parse_string(s: string, isStrict: boolean?)
	-- pre
	isStrict = not not isStrict
	-- assume that s is properly a string wrapped with string delimiters
	assert(type(s) == 'string')
	local pattern = `[{XML.patterns.attributeString}]`
	local delimA, delimB = s:sub(1, 1), s:sub(-1)
	assert(
		delimA:match(pattern)
		and delimB:match(pattern)
		and delimA == delimB,
		`Delimiter issue, check if both delimiters are the same and are valid: string: {s}`
	)
	
	-- main
	local result = ''
	parser:reset(s)
	parser:pop() -- first delim
	
	while parser.i <= #s - 1 do
		local escapeSequence = parser:c_pop('&%a%a%a?%a?;')
		local append
		if escapeSequence then
			append = XML.escapeSequences[escapeSequence]
		elseif parser:peek_match('<![CDATA[', true) then
			local a = parser:pop(8)
			local b, c = parser:pop_until(']]>', true)
			assert(a and b and c)
			
			local i = parser.i
			append = XML.parse_cdata(a .. b .. c)
			parser.i = i
			parser.referral = s
		else
			append = parser:pop()
		end
		assert(
			not(isStrict and append == delimA), 
			'delimiter inside string' .. parser:get_snapshot()
		)
		
		result ..= append
	end
	
	parser:pop() -- second delim
	
	return result
end

function XML.parse_xml(s: string)
	-- pre
	assert(type(s) == 'string')
	
	-- main
	-- parser:reset(s)
	XML.tokenize_xml(s)
	
	local result: {
		value: {tag};
		getDescendant: ({number}) -> tag
	}
	result = {
		value = {};
		getDescendant = function(t)
			assert(type(t) == 'table')
			local result = result

			for i = 1, #t do
				result = result.value[t[i]]
				
				if not result then
					break
				end
			end

			return result
		end,
	}
	
	
	local stack = {}
	
	while true do
		local tkStruct = XML.tokenizer.pop()
		
		if tkStruct.tkType == 'end' then
			break
		elseif tkStruct.tkType == 'tagStart' then
			
			-- create tag struct
			local tag: tag = {
				attributes = {};
				tag = tkStruct.token:sub(2);
			}
			
			-- set attributes
			while XML.tokenizer.peek().tkType == 'attributeIndex' do
				-- get index, '=', and value
				local indexStruct = XML.tokenizer.pop()
				
				local tkStructB = assert(XML.tokenizer.pop())
				assert(tkStructB.tkType == 'symbol')
				assert(tkStructB.token == '=')
				
				local valueStruct = assert(XML.tokenizer.pop())
				assert(valueStruct.tkType == 'attributeValue')
				
				-- set
				tag.attributes[indexStruct.token] = XML.parse_string(valueStruct.token, true)
			end
			
			-- get values
			local parent = result.getDescendant(stack)
			
			if not parent.value then
				parent.value = {}
			end

			-- insert into values
			tinsert(parent.value, tag)
			
			--  get complete
			local tagCompleteStruct = XML.tokenizer.pop()
			
			if tagCompleteStruct.tkType == 'emptyTagComplete' then
				-- considered empty, does not need stack mutation
				tag.isEmpty = true
			elseif tagCompleteStruct.tkType == 'tagComplete' then
				-- push stack
				tinsert(stack, #parent.value)
			else
				print(tkStruct)
				error('in tag: undefined token struct: ^')
			end
		elseif tkStruct.tkType == 'tagEnd' then
			-- pop stack
			local tagComplete = assert(XML.tokenizer.pop())
			assert(tagComplete.tkType == 'tagComplete')
			tremove(stack, #stack)
		elseif tkStruct.tkType == 'elementContent' then
			-- set tag value
			local tag = result.getDescendant(stack)
				
			if not tag.value  then
				tag.value = {}
			end
			tinsert(tag.value, XML.parse_string(`"{tkStruct.token}"`))
		else
			error('undefined token struct: ^')
		end
	end
	
	return result
end

return XML

