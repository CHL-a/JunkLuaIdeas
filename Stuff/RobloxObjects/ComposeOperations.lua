local module = {}

disguise = require(script.Parent.LuaUTypes).disguise

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

function module.append_argument(n: number, value: any)
	return function(...)
		local args = {...}
		
		table.insert(args, value)
		
		return unpack(args)
	end
end

return module
