local Map = require('./@CHL>Map')

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

function module.request(request: request, is_explicit_call: boolean): response 
	local http_enabled
	
	if is_explicit_call then
		http_enabled = service.HttpEnabled
		service.HttpEnabled = true
	end
	
	local response = service:RequestAsync(request)

	if is_explicit_call then
		service.HttpEnabled = http_enabled
	end
	
	return response
end

module.service = service

return module
