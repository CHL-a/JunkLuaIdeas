local module = {}

module.string = {}

function module.string.luaStringify(str, args)
	-- returns lua string
	-- pre
	assert(type(str) == 'string', 'bad arg #1, not string')
	assert(type(args) == 'table', 'bad arg #2, not table')
	local typeArgs = module.table.getType(args);
	assert(typeArgs == 'dictionary', 'bad arg #2, not dictionary, got' .. typeArgs)
	local stringType = args.stringType
	assert(stringType == 'single' or stringType == 'multiLined', 'arg2.stringType is invalid, got' .. tostring(stringType))

	if stringType == 'single' then
		local token = args.token
		assert(token == '"' or token == "'", 'bad token')
		args.beginToken = token
		args.endToken = token
	elseif stringType == 'multiLined' then
		local equalSignLength = args.equalSignLength or 0

		assert(type(equalSignLength) == 'number', 'got bad type for equalsignlength')
		assert(equalSignLength >= 0, 'equalSignLength out of range, smaller than 0')
		assert(equalSignLength % 1 == 0, 'not an integer')

		args.beginToken = '[' .. ('='):rep(equalSignLength) .. '['
		args.endToken =   ']' .. ('='):rep(equalSignLength) .. ']'
	else
		error'how'
	end

	-- main
	local result = args.beginToken

	for i = 1, #str do
		local char = str:sub(i, i)

		if stringType == 'single' then
			char = 
				char == args.beginToken and '\\' .. args.beginToken or -- ', "
				char == '\n' 			 and '\\n' 					or -- \n
				char == '\\' 			and '\\\\'					or -- \
				char
		elseif stringType == 'multiLined' then
			-- this v
			-- ]====]
			if char == ']' and str:sub(i - #args.beginToken + 1, i) == args.endToken then
				char = '\\]'
			end
		end

		result ..= char
	end

	result ..= args.endToken

	return result
end

function module.string.compare(strA, strB)
	-- pre
	assert(
		type(strA) == 'string' and 
			type(strB) == 'string'
	)

	strA = tostring(strA)
	strB = tostring(strB)

	-- main
	local result = false
	local lStr = #strA > #strB and strA or strB

	for i = 1, #lStr do
		local cA = strA:sub(i, i)
		local cB = strB:sub(i, i)
		local vA = cA == '' and -1 or cA:byte()
		local vB = cB == '' and -1 or cB:byte()

		if vA ~= vB then
			result = vA < vB
			break
		end
	end

	return result
end

module.table = {}

function module.table.getType(t)
	-- can return "array", "dictionary", "empty", "mixed" or "spotty array"
	assert(type(t) == 'table', 'BAD ARGUMENT: '.. debug.traceback())

	local result

	local stringIndexed = false
	local numberIndexed = false

	local iterations = 0

	for i in next, t do
		iterations = iterations + 1
		local typeI = type(i)

		if not stringIndexed and typeI == 'string'then
			stringIndexed = true
		elseif not numberIndexed and typeI == 'number'then
			numberIndexed = true
		end

		if numberIndexed and stringIndexed then
			-- both true, we got what we came for, break
			break
		end
	end

	-- assign result
	result = 
		result or
		numberIndexed and (
			stringIndexed and 'mixed' or 
			#t == iterations and 'array' or
			'spotty array'
		)or 
		stringIndexed and 'dictionary' or 
		'empty'

	assert(result, 'some how not met, nIndexed=' .. tostring(numberIndexed) .. ',sIndexed=' .. tostring(stringIndexed))

	return result
end

function module.table.indexN(t)
	local last
	local result = 0
	repeat
		last = next(t, last)
		result += 1
	until not last
	
	return result - 1
end

function module.table.isSugarIndex(str)
	-- pre
	assert(type(str) == 'string')

	-- main
	local c1 = str:sub(1,1)
	local suffix = str:sub(2)
	
	local result = c1:match('[%a_]') and (not suffix:match('[^%w_]') or suffix == '')

	return result
end


function module.table.toString(
	t: {[any]:any}, 
	indent_unit: string?,
	lvl: number?, 
	depth: number)
	-- displays content inside of the table
	-- pre
	depth = depth or 10
	assert(type(t) == 'table' and type(depth) == 'number')

	if depth <= 0 then return end
	lvl = lvl or 1
	assert(type(lvl) == 'number' and lvl >= 1)
	
	indent_unit = indent_unit or '    '
	assert(type(indent_unit) == 'string', `oops: {indent_unit}`)
	
	-- main
	local result = '{'

	local iterationRan = false

	local tableType = module.table.getType(t)
	local iterations = module.table.indexN(t)
	local currentIteration = 0

	local resultSections = {}

	for i,v in next, t do
		local ivStruct = {
			index = '';
			value = nil;
			precedingWhitespace = nil;
			separator = nil;
		}

		currentIteration = currentIteration + 1

		if not iterationRan then iterationRan = true end

		local tabs = (indent_unit :: string):rep(lvl)
		--local section = '\n' .. tabs
		ivStruct.precedingWhitespace = `\n{tabs}`

		-- handle indexes
		if tableType ~= 'array' then
			local isSugarIndex = type(i) == 'string' and 
				module.table.isSugarIndex(i) -- availble for indexes that comply with lua's sugar syntax for indexes

			if not isSugarIndex then -- possible bracket indication
				ivStruct.index ..= '['
			end

			ivStruct.index ..= (
				(isSugarIndex or type(i) == 'number') and 
					tostring(i) or 
					module.string.luaStringify(i, {
						stringType = 'single';
						token = "'"
					}
				)
			)

			if not isSugarIndex then
				ivStruct.index ..= ']'
			end

			--section = section .. ' = '
		end
		-- handle values

		local metatable = type(v) == 'table' and getmetatable(v)
		local tostringMeta = metatable and metatable.__tostring and metatable.__tostring()

		ivStruct.value = 
			type(v) == 'string' and 
				module.string.luaStringify(v, {
					stringType = v:match('[\n\t]') and 'multiLined' or 'single';
					token = "'"
				}) or 
			type(v) == 'table' and (
				tostringMeta and 
					table.concat(tostringMeta:split('\n'),`\n{tabs}`) or
					module.table.toString(v, indent_unit, lvl + 1, depth - 1) or 
					'(ended recursion, depth limit reached)'
				)or 
			tostring(v)

		-- concat
		--section = section .. printedValues .. 
		ivStruct.separator = (
			currentIteration == iterations and '' or
				tableType == 'array' and ',' or 
				';'
		)

		--result = result .. section

		table.insert(resultSections, ivStruct)
	end

	-- finallize and return
	if iterationRan then
		if tableType ~= 'array' then
			table.sort(resultSections, function (structA, structB)
				return module.string.compare(structA.index, structB.index)
			end)
		end
		local sections = ''

		for _, v in next, resultSections do
			sections ..= 
				v.precedingWhitespace .. 
				v.index .. 
				(tableType ~= 'array' and ' = ' or '') .. 
				v.value .. 
				v.separator
		end

		result ..=
			sections .. 
			'\n' .. 
			(indent_unit :: string):rep((lvl - 1))
	end

	result ..=  '}'
	return result
end


return module
