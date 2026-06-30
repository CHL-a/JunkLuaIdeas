--[[
	A badge service which mimics the actual service, but attempts to allow the use of promises

	If you request for a mock badge service, see CHL (Discord: @__chl), contact her with a dm or a ping with a reason and proof of discovery (take a screenshot of this long comment, 
		include the script tab)
]]

local module = {}

local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')

type promise<T...> = Promise.modified_object<T...>

Promise.implant()

module.service = game:GetService('BadgeService')

function module.award_badge(user: User, badge_id: number): promise<boolean>
	return Promise.try(module.service.AwardBadgeAsync, module.service, user, badge_id)
		:catch(function()return false end)
end

function module.check_user_badges(user: User, badge_ids: {number}): promise<{number}>
	return Promise.try(module.service.CheckUserBadgesAsync, module.service, user, badge_ids)
		:catch(function()return {} end)
end

export type badge_info = {
	IconImageId: number,
	Name: string,
	Description: string,
	Enabled: boolean,
	success: boolean;
}

function module.get_badge_info(badge_id: number): promise<badge_info>
	return Promise.try(module.service.GetBadgeInfoAsync, module.service, badge_id)
		:catch(function()return {} end)
		:tap(function(struct: badge_info) struct.success = not not struct.Name end)
end

function module.user_has_badge(user: User, badge_id: number): promise<boolean>
	return Promise.try(module.service.UserHasBadgeAsync, module.service, user, badge_id)
		:catch(function()return false end)
end

return module
