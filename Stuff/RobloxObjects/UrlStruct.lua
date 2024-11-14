local module = {}
local Objects = script.Parent

local Dash = require(Objects["@CHL/DashSingular"])

type map<I,V> = Dash.Map<I,V>

export type struct = {
	scheme: string;
	username: string?;
	password: string?;
	domain: string;
	domain_split: {string};
	port: number?;
	queries: map<string, string>?;
	fragment: string?;
	path: string;
	path_split: {string}
}

disguise = require(Objects.LuaUTypes).disguise
last = Dash.last

function module.parse(s: string): struct?
	local i = 1
	local j = 1
	local n = #s
	local result: struct = disguise{}

	-- scheme
	local slash_split = s:split('/')
	
	if not slash_split[1] then return end
	result.scheme = slash_split[1]:sub(1, -2)

	-- username and password pair
	if not slash_split[3] then return end
	local at_split = slash_split[3]:split('@')
	local other = at_split[1]
	
	if #at_split == 2 then
		result.username, result.password = unpack(at_split[1]:split(':'))
		other = at_split[2]
	end
	
	-- domain and port
	local colon_split = other:split(':')
	local domain = colon_split[1]
	
	result.domain = domain
	result.domain_split = domain:split('.')
	
	local port = colon_split[2]
	if port then
		result.port = tonumber(port)
		if not result.port then return;end
	end
	
	-- query and fragment
	local lastPath = last(slash_split)
	local question_mark_split = lastPath:split('?')
	
	local query = question_mark_split[2]
	local fragment
	
	if query then
		local queries = {}
		local amp_split = query:split('&')
		local amp_last = last(amp_split)
		
		local hash_split = amp_last:split('#')
		amp_split[#amp_split], fragment = unpack(hash_split)
		slash_split[#slash_split] = question_mark_split[1]
		
		for _, e in amp_split do
			local i, v = unpack(e:split('='))
			queries[i] = v
		end
		
		result.queries = queries
	else
		local hash_split = lastPath:split('#')
		slash_split[#slash_split], fragment = unpack(hash_split)
	end
	
	result.fragment = fragment
	
	-- path
	for i = 3, 1, -1 do
		table.remove(slash_split, i)
	end
	
	result.path_split = slash_split
	result.path = table.concat(slash_split, '/')
	
	
	return result
end

function module.toString(s: struct): string
	local result = `{s.scheme}:`
	
	if s.domain then
		result ..= '//'
		
		if s.username and s.password then
			result ..= `{s.username}:{s.password}@`
		end
		
		result ..= s.domain
		
		if s.port then
			result ..= `:{s.port}`
		end
	end
	
	result ..= `/{s.path}`
	
	if s.queries then
		result ..= '?'
		
		local i = next(s.queries)
		
		while i do
			result ..= `{i}={s.queries[i]}`
			
			i = next(s.queries, i)
			
			if i then
				result ..= '&'
			end
		end
	end
	
	if s.fragment then
		result ..= `#{s.fragment}`
	end
	
	return result
end

return module
