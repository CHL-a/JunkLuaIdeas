--[[
	Used as an uploading file service
]]
local Objects = game:GetService('ReplicatedStorage'):WaitForChild('Objects')
local MultipartFormData = require(Objects:WaitForChild('@CHL>MutlipartFormData'))
local HttpServiceWrapper = require('./@CHL>HttpServiceWrapper')
local Encoders = require(Objects:WaitForChild('@CHL>RobloxServiceEncoders'))

export type upload_response = {
	id: string;
	ext: string;
	type: string; -- MIME type
	checksum: string; -- md5 checksum
	key: string;
	link: string;
	delete: string;
}

export type upload_http_response = HttpServiceWrapper.response & {
	-- not guaranteed
	json: upload_response
}

export type object_response = {
	id: string;
	type: string;
	date: number;
	size: number;
	checksums: {
		md5: string
	};
	name: string?;
}

export type object_http_response = HttpServiceWrapper.response & {
	-- not guaranteed
	json: object_response
}

local module = {}

module.api = 'https://kappa.lol/api/'

function module.upload(file_content: string, mime_type: string, name: string?): upload_http_response
	name = name or 'unknown'

	local form = MultipartFormData.new()
	local struct

	struct = form:add(file_content)
	struct.content_disposition.name = 'file'
	struct.content_disposition.filename = name
	struct.content_type = mime_type -- 'application/octet-stream'

	local body = form:to_string()

	local response = HttpServiceWrapper.post(`{module.api}upload`, {['Content-Type'] = form:get_header_value()}, body)
	
	if response.Success then
		response.json = Encoders.encoding.json.decode(response.Body)
	end
	
	return response
end

function module.delete(key: string)
	local response = HttpServiceWrapper.post(`{module.api}delete?key={key}`)

	return response
end

function module.object(key: string): object_http_response
	local response = HttpServiceWrapper.get(`{module.api}object?key={key}`)
	
	if response.Success then
		response.json = Encoders.encoding.json.decode(response.Body)
	end
	
	return response
end

return module
