local Map = require('@game/ReplicatedStorage/Objects/@CHL>Map')
local Object = require('@game/ReplicatedStorage/Objects/Object')
local Class = require('@game/ReplicatedStorage/Objects/Class')
local Set = require('@game/ReplicatedStorage/Objects/@CHL>Set')
local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')

type dict<A> = Map.dictionary<A>
type map<I,V> = Map.simple<I,V>
type set<A> = Set.simple<A>
type promise<T...> = Promise.object<T...>

export type request_method = 'GET' | 'HEAD' | 'POST' | 'PUT' | 'DELETE' | 'OPTION' | 'TRACE' | 'PATCH'

--[[
	MODE: if using request, this mode decides if to use an instead or regular or both, webinstead first
--]]
export type request_mode = 'REGULAR' | 'WEBINSTEAD'

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

type instead_invoke = (self: instead, request) -> response

export type instead = {
	url_pattern: string;
	invoke: instead_invoke
} & Object.object_inheritance

module = {}
service = game:GetService('HttpService')
insteads = {} :: map<any, instead>

function module.request(request: request): response
	local response
	local mode: set<string> = module.request_mode
	
	if mode.WEBINSTEAD then
		local url = request.Url
		
		for _, v: instead in insteads do
			if not url:match(v.url_pattern) then continue end
			response = v:invoke(request)
			break
		end
	end
	
	if not response and mode.REGULAR then
		response = service:RequestAsync(request)
	end
	
	if not response then
		print(request)
		error(`fail: no response: \nmode={mode}`)
	end
	
	return response 
end

function method_request(method: request_method)
	return function(url: string, headers: dict<any>?, body: string?, compress: Enum.HttpCompression?)
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

function module.set_mode(i: request_mode, b: boolean)
	module.request_mode[i] = b
end

module.insteads = insteads
module.request_mode = {
	REGULAR = true;
	WEBINSTEAD = false;
} :: set<request_mode>
module.service = service

--########################################################################################
--########################################################################################
--########################################################################################

Instead = {}

function Instead.new(pattern: string, singleton_func: ((self: instead, request)->response)?): instead
	local self: instead = Object.from.class(Instead)
	
	self.url_pattern = pattern
	
	if singleton_func then
		self.invoke = singleton_func
	end
	
	return self
end

Instead.invoke = Class.abstractMethod

Class.makeProperClass(Instead, '@CHL>HttpServiceWrapper>WebInstead')

module.instead = Instead

--########################################################################################
--########################################################################################
--########################################################################################

export type promised_response = promise<response>

module.promise = {}
module.promise.request = Promise.promisify(module.request) :: (request)->promised_response
module.promise.get = Promise.promisify(module.get) :: (url: string, headers: dict<any>?, body: string?, compress: Enum.HttpCompression?) -> promised_response
module.promise.post = Promise.promisify(module.post) :: (url: string, headers: dict<any>?, body: string?, compress: Enum.HttpCompression?) -> promised_response

return module
