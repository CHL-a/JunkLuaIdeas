--[[
	mocks badge service for one specific person
	
	is subject to change for client compatability
]]

local Class = require('@game/ReplicatedStorage/Objects/Class')
local Object = require('@game/ReplicatedStorage/Objects/Object')
local RemoteFolder = require('@game/ReplicatedStorage/Objects/@CHL>RemoteFolder')
local BadgeService = require('./@CHL>BadgeService')
local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')
local module = {}

type promise<T...> = Promise.modified_object<T...>

module.default = game:GetService('BadgeService')
award_badge_event = RemoteFolder.static_get_event('award_badge')
empty = require('@game/ReplicatedStorage/Objects/LuaUTypes').empty

present_player = game:GetService('Players'):GetPlayers()[1]
service = {}

export type service = {} & BadgeService

function service.new(): service
	local self = Object.simple.new(service)
	
	return self
end

function service:AwardBadgeAsync(user: User, id: number): boolean
	if service.user_badge_set[id] then return false end
	
	service.user_badge_set[id] = true
	
	local name = service:GetBadgeInfoAsync(id).Name
	
	local promise = service.player
	
	if service.EXPLICIT_MISSING_PLAYER_WARN then
		promise = promise:timeout(20)
	end
	
	promise = promise:upon(function(player)award_badge_event:FireClient(player, name) end)
	
	if service.EXPLICIT_MISSING_PLAYER_WARN then
		promise:catch(warn)
	end
	
	return true
end

function service:CheckUserBadgesAsync(user:User, badgeIds:{number}): {number}
	local result = {}
	
	for _, id in badgeIds do
		if service.user_badge_set[id] then
			table.insert(result, id)
		end
	end
	
	return result
end

export type badge_info = BadgeService.badge_info

function service:GetBadgeInfoAsync(badge_id: number): badge_info
	local result
	
	if service.explicit_badge_info[badge_id] then
		result = service.explicit_badge_info[badge_id]
	elseif service.EXPLICIT_ACTUAL_BADGE_INFO_GET then
		result = module.default:GetBadgeInfoAsync(badge_id)
		
		service.explicit_badge_info[badge_id] = result
	else
		result = {
			IconImageId = 0,
			Name = 'Badge '..tostring(badge_id),
			Description = 'Badge '..tostring(badge_id),
			Enabled = true,
			success = true
		}
		
		service.explicit_badge_info[badge_id] = result
	end
	
	return result
end

function service:UserHasBadgeAsync(user: User, badge_id: number): boolean
	return service.user_badge_set[badge_id] ~= nil
end

Class.make_proper_class(service, '@CHL>FakeBadgeService')

service.user_badge_set = {}
service.explicit_badge_info = {}
service.player = Promise.from_event(award_badge_event.OnServerEvent) :: promise<Player>
service.EXPLICIT_MISSING_PLAYER_WARN = true
service.EXPLICIT_ACTUAL_BADGE_INFO_GET = true

module.service = service
module.singleton = service.new() :: service

return module
