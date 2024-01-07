--// TYPES
local Objects = script.Parent
local StringUtils = require(Objects["@CHL/StringUtils"])
local Dash = require(Objects["@CHL/DashSingular"])

type __object = {
	depth: number;
	tableOptions: __options;
	accessed: Dash.Set<Dash.Table>;
	
	parseToLines: (self: __object, v: any, __options) -> {string};
	parse: (self: __object, v: any, __options) -> string;
	clearAccessed: (self: __object) -> nil;
	reset: (self: __object) -> nil;
}
export type object = __object

type __options = {
	maxDepth: number?;
	indentUnit: string | '\t';
	stringArgs: StringUtils.luaSArgs?;
}
export type options = __options

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)
local disguise = LuaUTypes.disguise
local TableUtils = require(Objects["@CHL/TableUtils"])
local push = TableUtils.push
local defaultify = TableUtils.defaultify

module.__index = module

function assertType<A>(value: any | A, __type: string, msg: string?): A
	Dash.assertEqual(typeof(value), __type, msg or `Attempting to pass value, {
		value}, of type {typeof(value)}, and not {__type}`)
	return value
end

module.defaultOptions = {
	maxDepth = 10;
	indentUnit = '\t';
	stringArgs = {
		token = '\'';
		multilineType = 'single';
	}
} :: __options

function module.new(options: __options?): __object
	local self: __object = disguise(setmetatable({}, module))
	
	self.tableOptions = defaultify(options, module.defaultOptions)
	self.accessed = {}
	self.depth = 0
	
	return self
end

module.parseToLines = function(self: __object, v: any, op: __options): {string}
	-- pre
	op = TableUtils.defaultify(op, self.tableOptions)
	
	-- main
	if typeof(v) == 'table' then
		-- case of deep
		if self.depth > op.maxDepth then
			return {'* Max depth reached *'}
		end
		
		-- case of accessed
		if self.accessed[v] then return {'* Cyclic referencing reached *'}end
		
		-- case of metatable
		local meta = getmetatable(v) :: LuaUTypes.metatable<typeof(v)>?
		
		if meta and meta.__tostring then return tostring(v):split('\n') end
		
		-- case of empty
		if TableUtils.isEmpty(v) then return {'{}'}end
		
		-- other cases
		local result = {'{'}
		local isProperArray = TableUtils.isProperArray(v)

		self.accessed[v] = true
		
		for i: string, w: any in next, v do
			-- index
			if not isProperArray then
				i = `{StringUtils.sugarfy(i, op.stringArgs)} = `
			else
				i = ''
			end
			
			-- value
			self.depth += 1
			
			local wLines = self:parseToLines(w, op)
			
			self.depth -= 1
			
			wLines[1] = `{op.indentUnit}{i}{wLines[1]}`
			
			for i = 2, #wLines do
				wLines[i] = op.indentUnit .. wLines[i]
			end
			
			wLines[#wLines] = Dash.last(wLines) .. (isProperArray and ',' or ';')
			
			Dash.append(result, wLines)
		end
		
		return push(result, '}')
	elseif typeof(v) == 'string' then
		return {StringUtils.luaStringify(v, op.stringArgs)}
	end
	return {tostring(v)}
end

module.parse = function(self: __object, v: any, override): string
	return table.concat(self:parseToLines(v, override), '\n')
end

module.clearAccessed = function(self:__object)table.clear(self.accessed)end

module.reset = function(self: __object)
	self:clearAccessed()
	self.depth = 0
end


return module
