--[[
	unable to be tested, requires for me to buy badges

]]

local module = {}

service = game:GetService("BadgeService")

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

local Map = require('@game/ReplicatedStorage/Objects/@CHL>Map')
local Set = require('@game/ReplicatedStorage/Objects/@CHL>Set')

type map<K,V> = Map.simple<K,V>
type set<T> = Set.simple<T>

-- subject to change due to bot users existing, might be possible that a u64 is never enough
export type user_id_type = number
export type badge_id_type = number

export type user_badge_cache_raw = map<user_id_type, set<badge_id_type>>

set_operations = Set.simple.operations
user_badge_cache = {}
user_badge_cache.raw = {} :: user_badge_cache_raw
intersection = set_operations.intersection
union = set_operations.union
difference = set_operations.difference

function user_badge_cache.has(user_id: user_id_type, badge_id: badge_id_type): boolean?
	local user_badges = module.user_badge_cache[user_id]
	
	if not user_badges then return false end
	
	return user_badges[badge_id]
end

function user_badge_cache.has_multiple(onto: set<badge_id_type>?, user_id: user_id_type, check: set<badge_id_type>): set<badge_id_type>
	local result = onto or {}
	local user_badges = module.user_badge_cache[user_id]
	
	intersection(result, user_badges, check)
	
	return result
end

function user_badge_cache.add(user_id: user_id_type, badge_id: badge_id_type)
	local user_badges = module.user_badge_cache[user_id]
	
	if not user_badges then 
		user_badges = {}
		
		module.user_badge_cache[user_id] = user_badges
	end
	
	user_badges[badge_id] = true
end

module.user_badge_cache = user_badge_cache

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

export type badge_info = {
	Name: string,
	Description: string,
	IconImageId: number,
	IsEnabled: boolean,
}

players = game:GetService('Players')

default = {}

function player_count()return #players:GetPlayers()end

function default.award_async(user_id: user_id_type, badge_id: badge_id_type): boolean return service:AwardBadgeAsync(user_id, badge_id)end
function default.user_has_async(user_id: user_id_type, badge_id: badge_id_type)return service:UserHasBadgeAsync(user_id, badge_id)end
function default.get_award_limit()return 50 + 35 * player_count()end
function default.get_badge_info_async(badge_id: badge_id_type): badge_info? return service:GetBadgeInfoAsync(badge_id)end
function default.get_has_multiple_badge_limit()return 10 + 5 * player_count() end

function default.user_has_multiple_async(user_id: user_id_type, badges: {badge_id_type}): {badge_id_type}
	return service:CheckUserBadgesAsync(user_id, badges)
end

module.default = default

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

function module.user_has_async(user_id: user_id_type, badge_id: badge_id_type): boolean
	local result = user_badge_cache.has(user_id, badge_id)

	if not result then
		result = default.user_has_async(user_id, badge_id)

		if result then
			user_badge_cache.add(user_id, badge_id)
		end
	end

	return result
end

-- current issue: unimplemented limits
function module.user_has_multiple_async(onto: set<badge_id_type>?, user_id: user_id_type, badges: {badge_id_type}): set<badge_id_type>
	local result = onto or {}
	
	badges = Set.simple.from.arrays(badges)
	
	user_badge_cache.has_multiple(result, user_id, badges)
	
	local missing = Set.simple.difference(nil, badges, result)
	
	if not Set.simple.is_empty(missing) then
		local array_missing = Set.simple.to_array(missing)
		local sub_array = {}
		
		for i = 1, #array_missing, 10 do
			table.clone(sub_array)
			
			for j = 1, 10 do
				local k = i - 1 + j
				
				sub_array[j] = array_missing[k]
			end
			
			local success, array_set = pcall(default.user_has_multiple_async, user_id, sub_array)
			
			if not (success and result) then continue end
			
			for _, badge_id in array_set do
				user_badge_cache.add(user_id, badge_id)
			end
			
			union(result, result, Set.simple.from.arrays(array_set))
		end
	end
	
	return result
end

function module.award_async(arg_1: (Player | user_id_type), badge_id: badge_id_type): boolean
	local player: Player
	
	if typeof(arg_1) == 'Instance' then
		player = arg_1
	else
		player = players:GetPlayerByUserId(arg_1)
		
		if not player then return false end
	end
	
	local user_id: user_id_type = player.UserId
	
	local has_badge = module.user_has_async(user_id, badge_id)
	
	if has_badge then return false end
	
	local success, result = pcall(default.award_async, user_id, badge_id)
	
	if not success then
		warn(`[BadgeService]: failed to award badge {badge_id} to {user_id}: {result}`)
		return false
	end
	
	if result then
		user_badge_cache.add(user_id, badge_id)
	end
	
	return result
end

--####################################################################################################################################################
--####################################################################################################################################################
--####################################################################################################################################################

local ResponsiveCache = require('@game/ReplicatedStorage/Objects/@CHL>ResponsiveCache')

module.get_badge_info_cache = ResponsiveCache.new(default.get_badge_info_async) :: ResponsiveCache.object<(badge_info), (badge_id_type)>

function module.get_badge_info(badge_id: badge_id_type): badge_info return module.get_badge_info_cache:get(badge_id) end

module.service = service

return module
