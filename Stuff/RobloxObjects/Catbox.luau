--[[
	Used as temporary file service
]]
export type duration = '1h' | '12h' | '24h' | '72h'

local MultipartFormData = require('@game/ReplicatedStorage/Objects/@CHL>MultipartFormData')
local HttpServiceWrapper = require('./@CHL>HttpServiceWrapper')

local module = {}

module.temp = {}

function module.temp.upload(
	file_content: string, 
	mime_type: string, 
	duration: duration?, 
	name: string?,
	file_name_length_is_16: boolean?): HttpServiceWrapper.promised_response
	
	duration = duration or '1h'
	name = name or 'unknown'
	
	local form = MultipartFormData.new()
	local struct
	
	struct = form:add('fileupload')
	struct.content_disposition.name = 'reqtype'
	
	if file_name_length_is_16 then
		struct = form:add('16')
		struct.content_disposition.name = 'fileNameLength'
	end
	
	struct = form:add(duration)
	struct.content_disposition.name = 'time'
	
	struct = form:add(file_content)
	struct.content_disposition.name = 'fileToUpload'
	struct.content_disposition.filename = name
	struct.content_type = mime_type
	
	local body = form:to_string()
	
	local response = HttpServiceWrapper.promise.post(module.temp.api, {['Content-Type'] = form:get_header_value()}, body)
	
	return response
end

module.temp.api = 'https://litterbox.catbox.moe/resources/internals/api.php'

return module
