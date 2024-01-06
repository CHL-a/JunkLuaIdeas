--// TYPES
type __multilineType = 'single' | 'multiline'
export type multilineType = __multilineType

type __singleLineTokens = '"' | "'"
export type singleLineTokens = __singleLineTokens

type __luaSArgs = {
	multilineType: __multilineType;
	token: __singleLineTokens?;
	equalSigns: number?;
	prefix: string?;
	suffix: string?;
}
export type luaSArgs = __luaSArgs

--// MAIN
local module = {}
local Objects = script.Parent
local disguise = require(Objects.LuaUTypes).disguise

insert = table.insert

function isSugarIndex(i: string)return not not i:match('^[%a_][%w_]*$')end

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

function luaStringTokenize(str: string, args: __luaSArgs): {string}
	local result = string.split(str)
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

function luaStringify(str: string, args: __luaSArgs?)
	-- pre
	local a = disguise(args or {})::__luaSArgs
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

function sugarfy(i: string, args: __luaSArgs?)
	if isSugarIndex(i) then return i;end
	i = luaStringify(i, args)
	return `[{i}]`
end

module.compareStrings = compareStrings
module.luaStringify = luaStringify
module.luaStringTokenize = luaStringTokenize
module.isSugarIndex = isSugarIndex
module.sugarfy = sugarfy

return module
