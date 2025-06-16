module = {}

disguise = require('./LuaUTypes').disguise

function module.modify_argument(
	f: <A..., B...>(A...)->B..., 
	start: number?,
	last_arg: number?)
	
	start = start or 1
	last_arg = last_arg or start
	
	return function(...)
		local args = {...}
		local f_result = {f(unpack(args, start, last_arg))}
		for i = disguise(start), disguise(last_arg) do
			args[i] = f_result[i - disguise(start) + 1]
		end
		
		return unpack(args)
	end
end

function module.append_argument(value: any, n: number?)
	return function(...)
		local args = {...}
		
		if not n then
			table.insert(args, value)
		else
			table.insert(args, n, value)
		end
		
		return unpack(args)
	end
end

return module
