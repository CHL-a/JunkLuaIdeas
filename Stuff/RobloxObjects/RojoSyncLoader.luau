--[[
	An instance buildier which uses github to load typical roblox package, maybe
]]

local GAIB = require('./@CHL>GitHubApiInstanceBuilder')
local HttpService = require('./@CHL>HttpServiceWrapperP')
local Encoders = require('./@CHL>RobloxServiceEncoders')

type tree = GAIB.v2_tree
type tree_inst = GAIB.v2_instance

local dash = require('./@CHL>DashSingular')

compose = dash.compose
module = {}

v1 = {}
v1.from = {}

function reformat_singular(instance: Instance)
	local init = instance:FindFirstChild('init')

	if init then
		local temp = instance

		for _, v in temp:GetChildren() do
			if v == init then continue end
			v.Parent = init
		end

		init.Parent = temp.Parent
		init.Name = temp.Name

		temp:Destroy()

		instance = init
	end
	
	return instance
end

function v1.reformat(instance: Instance): Instance
	instance = reformat_singular(instance)
	
	local descendants = instance:GetDescendants()
	
	for _, v in descendants do
		reformat_singular(v)
	end
	
	return instance
end

function v1.from.sha_hash_set(sha_hash: string, repo_set: string, suffix: string, branch: string?): Instance
	local u = `https://api.github.com/repos/{repo_set}/git/trees/{sha_hash}?recursive=true`
	local success, response: HttpService.response = pcall(HttpService.get, u)
	
	if not success or not response.Success then
		print(response)
		error('no success')
	end
	local json = Encoders.encoding.json.decode(response.Body)
		
	return v1.build(json, repo_set, suffix, branch)
end

v1.build = compose(GAIB.v2.build, v1.reformat) :: (tree: tree, repo_set: string, suffix: string) -> Instance

module.v1 = v1


return module
