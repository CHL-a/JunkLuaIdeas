local module = {}

export type general<I,V> = {[I]:V}
export type general_any = general<any, any>

disguise = require('./LuaUTypes').disguise
tclone = table.clone
tinsert = table.insert

function module.is_empty(a: general_any): boolean return next(a) == nil end

function module.deep_soft_index<A, B>(t: general_any, ...: A): B?
	for i = 1, select('#', ...) do
		local index = select(i, ...)
		t = t[index]

		if not t then return end
	end

	return disguise(t);
end

function module.safe_set(t: any, i: any, v: any): (boolean, string?)
	return pcall(function()
		t[i] = v
	end)
end

function module.imprint<A>(t: A, t2: general_any, should_warn: boolean?): A
	for i, v in next, t2 do
		local s, e = module.safe_set(t, i, v)
		if should_warn and not s then
			warn(e)
		end
	end

	return t
end

function module.push<A, B>(t: A, ...: B): A
	for i = 1, select('#', ...) do
		local a = select(i, ...)
		tinsert(disguise(t), a)
	end
	return t
end

-- might be moved somewhere else
function module.clear_nils<A>(t: A): A
	local i = 1
	local b = disguise(t)

	while i <= #b do
		if b[i] == nil then
			table.remove(b,i)
			i -= 1
		end
		i += 1
	end

	return t
end

-- specific function which takes arg ground and fills the missing values from arg concrete
function module.fill<A>(ground: A?, concrete: A): A
	local a, b = disguise(ground, concrete)
	if not a then
		return disguise(tclone(b))
	end
	
	for i, v in b do
		if a[i] == nil then
			a[i] = v
		end
	end
	
	return disguise(ground)
end

function module.defaultify<A>(arg: A?, default: A): A
	return not arg and default or module.fill(arg, default)
end

function module.is_proper_array(array: general_any): boolean
	return type(disguise(next(array))) == 'number' and next(array, #array) == nil
end

--[[do not use cyclic tables]]
function module.deep_clone<A>(t: A): A
	local a = tclone(disguise(t) :: {}) 
	
	local list = {a}
	
	while #list > 0 do
		local b = table.remove(list, 1)
		
		for i, v in b do
			if type(v) == 'table' then
				v = tclone(v)
				
				tinsert(list, v)
			end
		end
	end
	
	return a
end

function module.value_set<I, V>(t: general<I,V>): {[V]: true}
	local result = {}
	
	for _, v in t do 
		result[v] = true
	end
	
	return result
end

function module.keys<I,V>(t: general<I, V>):{I}
	local result = {}
	
	for i in t do
		tinsert(result, i)
	end
	
	return result
end

function module.random_value_of<I,V>(t: general<I,V>, random: Random?): V
	local keys = module.keys(t)
	local index = random and random:NextInteger(1, #keys) or math.random(1, #keys)
	local value = t[keys[index]]
	return value
end

function module.entry_amount(t: general_any)
	local result = 0
	
	for _ in t do
		result += 1
	end
	
	return result
end

export type table_type = 'array' | 'dictionary' | 'empty' | 'mixed' | 'spotty array' | 'odd'

function module.get_type(t: general_any): table_type
	local result;
	local has_string_index = false
	local has_number_index = false
	local iterations = 0

	for i in t do
		iterations += 1

		local type_i = typeof(i)

		if not has_string_index and type_i == 'string'  then
			has_string_index = true
		elseif has_number_index and type_i == 'number' then
			has_number_index = true
		elseif type_i~='string' and type_i ~= 'number' then
			return 'odd'
		end

		if has_string_index and has_number_index then
			break
		end
	end

	if has_number_index then
		if has_string_index then
			result = 'mixed'
		elseif iterations == #t then
			result = 'array'
		else
			result = 'spotty array'
		end
	elseif has_string_index then
		result = 'dictionary'
	elseif iterations == 0 then
		result = 'empty'
	else
		print(t)
		error('how did we get here?')
	end

	return result
end


return module
