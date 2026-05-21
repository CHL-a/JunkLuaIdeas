export type creator_type = 'User' | 'Group'

export type creator = {
	CreatorType: creator_type,
	CreatorTargetId: number,
	HasVerifiedBadge: boolean,
	Name: string,
	Id: number,
}

export type product_struct = {
	Name: string,
	Description: string?,
	PriceInRobux: number,
	ProductId: number,
	ProductType: string,
	Created: string,
	Updated: string,
	ContentRatingTypeId: number,
	MinimumMembershipLevel: number,
	IsPublicDomain: boolean,
	TargetId: number,
	Creator: creator;
}

export type asset_extension = {
	AssetId: number,
	AssetTypeId: number,
	IconImageAssetId: number,
	IsForSale: boolean,
	IsLimited: boolean,
	IsLimitedUnique: boolean,
	IsNew: boolean,
	Remaining: number,
	Sales: number,
}

export type collectable_item_details = {
	CollectibleLowestAvailableResaleItemInstanceId: number,
	CollectibleLowestAvailableResaleProductId: number,
	CollectibleLowestResalePrice: number,
	IsForSale: boolean,
	IsLimited: boolean,
	TotalQuantity: number,
}

export type collectable_extension = {
	CollectibleItemId: string,
	CollectibleProductId: string,
	CollectiblesItemDetails: collectable_item_details;
}

export type sale_location = {
	SaleLocationType: number;
	UniverseIds: {number}
}

export type sale_location_settings = {
	CanBeSoldInThisGame: boolean;
	SaleLocations: sale_location;
}

export type product_info_result = product_struct & asset_extension & collectable_extension & sale_location_settings

local ResponsiveCache = require('./@CHL>ResponsiveCache')
local module = {}
local get_product_info_cache = ResponsiveCache.new(function(asset_id: number, info_type: Enum.InfoType?)
	return service:GetProductInfoAsync(asset_id, info_type)
end)

service = game:GetService('MarketplaceService')

function module.get_product_info_async(asset_id: number, info_type: Enum.InfoType?): product_info_result
	local result = get_product_info_cache:get(asset_id, info_type)
	
	if not result then
		-- result can return nil, no explaination of why
		get_product_info_cache:decache(asset_id, info_type)
	end
	
	return result
end

module.service = service

return module
