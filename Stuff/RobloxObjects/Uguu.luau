-- another file uploader
local MultipartFormData = require('@game/ReplicatedStorage/Objects/@CHL>MultipartFormData')
local HttpServiceWrapper = require('./@CHL>HttpServiceWrapper')
local Promise = require('@game/ReplicatedStorage/Objects/@CHL>Promise')
local Encoders = require('@game/ReplicatedStorage/Objects/@CHL>RobloxServiceEncoders')

export type response = HttpServiceWrapper.response & {
	json: {
		errors: {any};
		files: {
			{
				dupe: boolean;
				filename: string;
				mimetype: string;
				size: number;
				url: string;
			}
		};
		success: boolean;
	}
}

local module = {}

function module.middle_json(response: response)
	local s, m = pcall(Encoders.encoding.json.decode, response.Body)
	if s then
		response.json = m
	else
		print(response.Body)
		error(m)
	end
end

function module.upload(
	file_content: string, 
	mime_type: string, 
	name: string?): Promise.modified_object<HttpServiceWrapper.response>
	
	local form = MultipartFormData.new()
	local struct
	
	struct = form:add(file_content)
	struct.content_disposition.name = 'files[]'
	struct.content_disposition.filename = name
	struct.content_type = mime_type
	
	local body = form:to_string()
	
	local response = HttpServiceWrapper.promise.post(module.api, {['Content-Type'] = form:get_header_value()}, body)
		:tap(module.middle_json)
	
	return response
end

module.api = 'https://uguu.se/upload.php'

return module
