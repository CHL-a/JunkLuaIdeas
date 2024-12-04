--// TYPES
export type multilineType = 'single' | 'multiline'
export type singleLineTokens = '"' | "'"

export type luaSArgs = {
	multilineType: multilineType;
	token: singleLineTokens?;
	equalSigns: number?;
	prefix: string?;
	suffix: string?;
}

--// MAIN
local module = {}
local Objects = script.Parent
local disguise = require(Objects.LuaUTypes).disguise

insert = table.insert

function isSugarIndex(i: string)return not not i:match('^[%a_][%w_]*$')end
function camelCaseify(s: string)return s:sub(1,1):lower() .. s:sub(2)end

function compareStrings(strA: string, strB: string): boolean
	-- pre
	assert(
		type(strA) == 'string' and 
			type(strB) == 'string'
	)

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

function luaStringTokenize(str: string, args: luaSArgs): {string}
	local result = str:split''
	insert(result, 1, args.prefix)
	
	local i = 2
	
	while i <= #result do
		local v = result[i]

		if args.multilineType == 'single' then
			if v == args.suffix then
				result[i] = `\\{v}`
			elseif v == '\n' then
				result[i] = '\\n'
			elseif v == '\\' then
				result[i] = '\\\\'
			end
		elseif v == ']' then
			local j = i
			repeat
				i += 1
			until result[i] ~= '='
			
			if i - j - 1 == args.equalSigns then
				result[i] = '\\]'
			end
		end
		
		i += 1
	end
	
	insert(result, args.suffix)
	return result
end

function luaStringify(str: string, args: luaSArgs?)
	-- pre
	local a = disguise(args or {})::luaSArgs
	a.multilineType = a.multilineType or 'single'
	a.equalSigns = a.equalSigns or 0
	a.token = a.token or '\''
	
	if a.multilineType == 'single' then
		a.prefix = a.token
		a.suffix = a.token
	else
		local s = ('='):rep(a.equalSigns)
		a.prefix = `[{s}[`
		a.suffix = `]{s}]`
	end
	
	-- main
	return table.concat(luaStringTokenize(str, a))
end

function sugarfy(i: string, args: luaSArgs?)
	if isSugarIndex(i) then return i;end
	if typeof(i) == 'string' then
		i = luaStringify(i, args)
	end
	return `[{i}]`
end

Iterator = {}

function Iterator.init_simple(s: string)
	return Iterator.simple, s, 0
end

function Iterator.simple(s: string, i: number)
	i += 1
	if i > #s then return;end
	return i, s:sub(i,i)
end

module.Iterator = Iterator
module.camelCaseify = camelCaseify
module.compareStrings = compareStrings
module.luaStringify = luaStringify
module.luaStringTokenize = luaStringTokenize
module.isSugarIndex = isSugarIndex
module.sugarfy = sugarfy

return module
