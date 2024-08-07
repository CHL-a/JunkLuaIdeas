--[[
	The unlisted types aren't implemented by Roblox and Roblox only
]]

type map<I,V> = {[I]:V}
type dict<T> = map<string,T>

--######################################################################################
--######################################################################################
--######################################################################################

-- http stuff

export type http_headers = dict<string>

export type http_request = {
	Url: string;
	Method: string?;
	Headers: http_headers?;
	Body: string?;
}

export type http_response = {
	Success: boolean;
	Body: string;
	StatusCode: number;
	StatusMessage: string;
	Headers: http_headers?
}

--######################################################################################
--######################################################################################
--######################################################################################

-- receipt

export type marketplace_receipt = {
	CurrencySpent: number;
	PlaceIdWherePurchased: number;
	PlayerId: number;
	ProductId: number;
	PurchaseId: string;
}

export type marketplace_developer_product = {
	DeveloperProductId: number;
	Name: string;
	PriceInRobux: number;
	ProductId: number;
	displayName: string;
}

--######################################################################################
--######################################################################################
--######################################################################################

-- non specific

export type ban_history_page = {
	DisplayReason: string;
	PrivateReason: string;
	StartTime: string;
	Duration: number;
	Ban: boolean;
	PlaceId: number;
}

export type user_info_item = {
	Id: number;
	Username: string;
	DisplayName: string;
	HasVerifiedBadge: boolean;
}

--######################################################################################
--######################################################################################
--######################################################################################

--######################################################################################
--######################################################################################
--######################################################################################

return true
