--[[
	EXTREME NOTE:
	
	This version of HttpServiceWrapper is much more liberal with how requests are invoked.
	
	See HttpServiceWrapper.request
]]

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

--[[
	Makes a http request to the specified url
	request (request)
	is_forced_call (boolean?): 
		Forces the http request to be made even if the HttpEnabled is false, be BENEVOLENT with how you force calls.
		This is an exceedingly dangerous parameter for external/non-CHL plugins. Use at your own risk.
]]
function module.request(request: request, is_forced_call: boolean?): response 
	local http_enabled
	
	if is_forced_call then
		http_enabled = service.HttpEnabled
		service.HttpEnabled = true
	end
	
	local response = service:RequestAsync(request)

	if is_forced_call then
		service.HttpEnabled = http_enabled
	end
	
	return response
end

type method_request_func = (url: string, headers: dict<any>?, body: string?, compress: Enum.HttpCompression?, is_explicit_call: boolean?)->response;

function method_request(method: request_method)
	return function(url: string, headers: dict<any>?, body: string?, compress: Enum.HttpCompression?, is_explicit_call: boolean?): response
		return module.request({
			Method = method;
			Url = url;
			Headers = headers;
			Body = body;
			Compress = compress;
		}, is_explicit_call)
	end
end

module.get = method_request('GET') :: method_request_func
module.post = method_request('POST') :: method_request_func

module.service = service

return module
