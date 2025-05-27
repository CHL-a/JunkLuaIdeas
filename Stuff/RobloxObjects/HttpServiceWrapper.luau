local Objects = game:GetService('ReplicatedStorage').Objects
local Map = require(Objects["@CHL>Map"])

type dict<A> = Map.dictionary<A>

export type request_method = 'GET' | 'HEAD' | 'POST' | 'PUT' | 'DELETE' | 'OPTION' | 'TRACE' | 'PATCH'

export type request = {
	Url: string;
	Method: request_method?;
	Headers: dict<any>?;
	Body: string?;
	Compress: Enum.HttpCompression?
}

export type response = {
	Success: boolean;
	StatusCode: number;
	StatusMessage: string;
	Headers: dict<any>;
	Body: any;
}

module = {}
service = game:GetService('HttpService')

function module.request(request: request): response return service:RequestAsync(request) end

module.service = service

return module
