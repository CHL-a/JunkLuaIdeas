-- promised version of HttpServiceWrapperP

local HttpServiceWrapper = require('./@CHL>HttpServiceWrapperP')
local PromiseTypes = require('./@CHL>PromiseTypes')
local Map = require('./@CHL>Map')

local Promise = PromiseTypes.modified.get()

type dict<T> = Map.dictionary<T>
type promise<T> = PromiseTypes.modified_object<T>

export type request = HttpServiceWrapper.request
export type response = HttpServiceWrapper.response
export type request_method = HttpServiceWrapper.request_method
export type response_promise = promise<response>

local module = {}

function module.request(request: request): response_promise
	return Promise.new(function(resolve, reject)
		local response, message = pcall(HttpServiceWrapper.request, request)
		
		if response then
			resolve(response)
		else
			reject(message)
		end
	end)
end

function method_request(method: request_method)
	return function(url: string, headers: dict<any>?, body: string?, compress: Enum.HttpCompression?): response_promise
		return module.request({
			Method = method;
			Url = url;
			Headers = headers;
			Body = body;
			Compress = compress;
		})
	end
end

module.get = method_request('GET')
module.post = method_request('POST')

return module
