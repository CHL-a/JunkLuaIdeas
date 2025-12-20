--[[
	Attempts to load sources from github
]]

local UrlStruct = require('./@CHL>UrlStruct')
local Dash = require('./@CHL>DashSingular')
local TableUtils = require('./@CHL>TableUtils')

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- v1
local HttpServiceP = require('./@CHL>HttpServiceWrapperP')
local RobloxServiceEncoders = require('./@CHL>RobloxServiceEncoders')
local Map = require('./@CHL>Map')

type response = HttpServiceP.response

export type v1_base = {
	name: string;
	path: string;
	download_url: string?;
	type: "dir" | 'file'
}

local module = {}

v1 = {}
tremove = table.remove
json_decode = RobloxServiceEncoders.encoding.json.decode
tinsert = table.insert

function chop_file_extention(s: string)
	local result = s:split('.')
	tremove(result)
	return table.concat(result, '.')
end

function json_get_async(url: string): (boolean, string | response, Map.dictionary<any>?)
	local success, value = pcall(function()
		return HttpServiceP.get(url)
	end)
	
	local third
	
	if success and value.Success then
		third = json_decode(value.Body)
	end
	
	return success, value, third
end

function v1.build(init: {v1_base}, prefix: string): Folder?
	local result = Instance.new('Folder')
	local success = true
	local queue = table.create(#init * 2)
	
	for i, v in init do
		queue[i * 2 - 1] = result
		queue[i * 2] = v
	end
	
	while #queue > 0 do
		local parent = tremove(queue, 1)
		local value: v1_base? = tremove(queue, 1)
		
		if not value then break;end
		
		local i: Instance
		
		if value.type == 'file' then
			local url = value.download_url
			local response, dict = nil
			
			assert(url, `missing download_url from: {value.name}`)
			
			response = HttpServiceP.get(url)
			
			if not success or not response.Success then warn(response)end
			
			local temp = Instance.new('ModuleScript')
			local source = response.Body
			
			temp.Source = source
			temp.Name = chop_file_extention(value.name)
			
			i = temp
		elseif value.type == 'dir' then
			local temp = Instance.new('Folder')
			temp.Name = value.name

			local list, response = nil
			
			success, response, list = json_get_async(`{prefix}{value.path}`)
			
			if not success then 
				warn(response)
			else
				for _, v in list do
					tinsert(queue, temp)
					tinsert(queue, v)
				end
			end
			
			i = temp
		else
			error(`Invalid value type: {value.type}`)
		end

		if not success then 
			result:Destroy()
			return
		end
		
		i.Parent = parent
	end
	
	return result
end

v1.from = {}

function v1.from.url(s: string)
	local u_struct = UrlStruct.parse(s)
	local success, base = pcall(function()
		local response = HttpServiceP.get(s)
		assert(response.Success)
		
		return json_decode(response.Body)
	end)
	
	assert(success, `Error occured: url={s}\nreason={base}`)
	
	for i = 5, #u_struct.path_split do
		u_struct.path_split[i] = nil
	end
	
	u_struct.path = table.concat(u_struct.path_split, '/')
	
	return v1.build(base, `{UrlStruct.toString(u_struct)}/`)
end

module.v1 = v1

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- v2
-- subject to change
export type v2_instance = {
	path: string;
	type: 'blob' | 'tree'
}

export type v2_tree = {
	tree: {v2_instance}
}

v2 = {}

function v2.check_repo_set(s: string)
	assert(s:find('/'), 'Reposet needs {owner}/{repo}')
end

function v2.get_raw_url(repo_set: string, suffix: string, branch: string?)
	v2.check_repo_set(repo_set)
	return `https://raw.githubusercontent.com/{repo_set}/refs/heads/{branch or 'main'}/{suffix}`
end

function v2.build(tree: v2_tree, repo_set: string, suffix: string, branch: string?): Folder
	local result = Instance.new('Folder')
	
	for _, v in tree.tree do
		local instance = nil
		local name_split = v.path:split('/')
		local last = tremove(name_split)
		
		local parent = TableUtils.deepSoftIndex(result, unpack(name_split))
		
		if v.type == 'tree' then
			instance = Instance.new('Folder')
		elseif v.type == 'blob' then
			instance = Instance.new('ModuleScript')
			local url = v2.get_raw_url(repo_set, `{suffix}/{v.path}`, branch)
			
			local suc, response = pcall(function(...)
				return HttpServiceP.get(url)
			end)
			
			if not suc or not response.Success then
				result:Destroy()
				error(`Got error: \n> url={url}\n> src={response}`)
			end
			
			local source = response.Body
			
			instance.Source = source
			last = chop_file_extention(last)
		else
			error(`bad type: got: {v.type}`)
		end
		
		instance.Name = last
		instance.Parent = parent
	end
	
	return result
end

v2.from = {}

function v2.from.sha_hash(h: string, repo_set: string, suffix: string, branch: string?): Folder
	local u = `https://api.github.com/repos/{repo_set}/git/trees/{h}?recursive=true`
	local _, _, json = json_get_async(u)
	
	assert(json)
	
	return v2.build(json, repo_set, suffix, branch)
end

module.v2 = v2

return module
