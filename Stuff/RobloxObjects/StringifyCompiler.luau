--// TYPES
local StringUtils = require('./@CHL>StringUtils')
local Dash = require('./@CHL>DashSingular')

export type object = {
	depth: number;
	table_options: options;
	accessed: Dash.Set<Dash.Table>;
	
	parse_to_lines: (self: object, v: any, options?) -> {string};
	parse: (self: object, v: any, options) -> string;
	clear_accessed: (self: object) -> ();
	reset: (self: object) -> ();
}

export type options = {
	maxDepth: number?;
	indentUnit: string | '\t';
	stringArgs: StringUtils.lua_string_args?;
}

--// MAIN
local module = {}
local LuaUTypes = require('./LuaUTypes')
local TableUtils = require('./@CHL>TableUtils')
local Object = require('./Object')
local Class = require('./Class')

disguise = LuaUTypes.disguise
push = TableUtils.push
defaultify = TableUtils.defaultify

module.defaultOptions = {
	maxDepth = 10;
	indentUnit = '\t';
	stringArgs = {
		token = '\'';
		multilineType = 'single';
	}
} :: options

function module.new(options: options?): object
	local self: object = Object.simple.new(module)
	
	self.table_options = defaultify(options, module.defaultOptions)
	self.accessed = {}
	self.depth = 1
	
	return self
end

function module.parse_to_lines(self: object, v: any, op: options): {string}
	-- pre
	op = TableUtils.defaultify(op, self.table_options)
	
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
			
			local wLines = self:parse_to_lines(w, op)
			
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

function module.parse(self: object, v: any, override): string
	return table.concat(self:parse_to_lines(v, override), '\n')
end

function module.clear_accessed(self:object)table.clear(self.accessed)end

function module.reset(self: object) self:clear_accessed()self.depth = 1 end

Class.makeProperClass(module, '@CHL>StringifyCompiler')

return module
