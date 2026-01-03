export type struct = {
	channel: string;
	token: string;
}

local module = {}

module.base_url = 'https://discord.com/api/webhooks/'

module.struct = {}
module.struct.from = {}
module.struct.to = {}

function module.struct.from.string(s: string): struct
	local base_url_length = #module.base_url
	local prefix = s:sub(1, base_url_length)
	local suffix = s:sub(base_url_length + 1)
	
	assert(module.base_url == prefix)
	
	local channel, token = suffix:match('^(%d+)/(.+)$')
	
	local result = {
		channel = channel,
		token = token
	}
	
	return result
end

function module.struct.to.string(self: struct): string
	return `{module.base_url}{self.channel}/{self.token}`
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Objects = game:GetService("ReplicatedStorage"):WaitForChild("Objects")

local BufferWrapper = require(Objects["@CHL>BufferWrapper"])
local BinaryStream = require(Objects["@CHL>BinaryStream"])

type buffer_w = BufferWrapper.object

--[[
	Current structure
	u32 version
	u16 token length
	string token
	u8 channel chunk count
	u8 partial chunk length
	u32[] full chunks
	u32 partial chunk
]]

function module.struct.to.buffer_w(struct: struct): buffer_w
	local token = struct.token
	local channel = struct.channel
	
	local consumer = BufferWrapper.consumer.new()
	local writer = BinaryStream.writer.new(consumer)
	
	-- version as u32
	writer:writeu32(0)
	
	-- length based string for tokens
	writer:writeu16(#token)
	writer:write_string(token)
	
	-- channel is always full of digits, so the solution is to split the channel into chunks (9 digits in radix 10)
	local channel_length = #channel
	local full_chunks = channel_length // 9
	local partial_length = channel_length % 9
	
	writer:writeu8(full_chunks)
	writer:writeu8(partial_length)
	
	for i = 1, full_chunks do
		local chunk = channel:sub(1, 9)
		writer:writeu32(tonumber(chunk))
		channel = channel:sub(10)
	end
	
	if partial_length > 0 then
		writer:writeu32(tonumber(channel))
	end
	
	return consumer:build()
end

function module.struct.to.buffer(struct: struct): buffer
	return module.struct.to.buffer_w(struct).referral
end

function module.struct.from.buffer(buff: buffer): struct
	local it = BufferWrapper.iterator.new(buff)
	local reader = BinaryStream.reader.new(it)
	
	local dw_version = reader:readu32()
	
	-- possible versions later
	assert(dw_version == 0)
	
	local token_length = reader:readu16()
	local token = reader:read_string(token_length)
	
	local channel_chunks = reader:readu8()
	local partial_chunk_length = reader:readu8()
	
	local channel = ""
	
	for i = 1, channel_chunks do
		local full_chunk = tostring(reader:readu32())
		
		local zero_left_fill_string_pattern = "%09s"
		full_chunk = full_chunk:format(zero_left_fill_string_pattern)
		
		channel ..= full_chunk
	end
	
	if partial_chunk_length > 0 then
		local partial_chunk = tostring(reader:readu32())
		local zeros = partial_chunk_length - #partial_chunk
		
		channel ..= ('0'):rep(zeros) .. partial_chunk
	end
	
	return {
		token = token;
		channel = channel
	}
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Map = require(Objects["@CHL>Map"])
local Object = require(Objects.Object)
local Class = require(Objects.Class)
local Dash = require(Objects["@CHL>DashSingular"])
local http = require('./@CHL>HttpServiceWrapper') -- subject to revision because plugin has a different environment
local MultipartFormData = require(Objects['@CHL>MutlipartFormData'])
local DiscordObjects = require(Objects["@CHL>DiscordObjects"])

type map<I, V> = Map.simple<I, V>
type dict<T> = Map.dictionary<T>
type attachment = MultipartFormData.part_struct

export type payload = {
	-- standard message content
	content: string?;

	-- optional username change
	username: string?;

	-- optional avatar change
	avatar_url: string?;

	-- is tts msg
	tts: boolean?;

	embeds: {DiscordObjects.embed}?; -- {embed}
	-- allowed_mentions: allowed mentions object
	-- attachments: {attachments}
	flags: number?;
	thread_name: string?;
	--applied_tags: {string}?
}

-- primary object which should make post requests seem easier as an interface
export type object = {
	-- see DiscordWebhook.struct for the struct type
	webhook: buffer;
	payload: payload;
	attachments: {attachment};
	
	add_attachment: (self: object, content: string, mime_type: string?, file_name: string?)->attachment;
	post: (object: object) -> ();
}

compose = Dash.compose
module.object = {}
module.object.from = {}
quick_to_url = compose(module.struct.from.buffer, module.struct.to.string) :: (webhook: buffer) -> string
disguise = require(Objects.LuaUTypes).disguise

function module.object.new(webhook: buffer): object
	local self: object = Object.simple.new(module.object)
	
	self.webhook = webhook
	self.payload = disguise{}
	self.attachments = {}
	
	return self
end

function module.object.add_attachment(self: object, content: string, mime_type: string?, file_name: string?): attachment
	local attachment: attachment = {
		content = content;
		content_type = mime_type or 'text/plain';
		content_disposition = {
			name = 'blank';
			filename = file_name or 'unknown'
		}
	}
	
	table.insert(self.attachments, attachment)
	
	return attachment
end

function module.object.post(self: object): http.response
	local webhook = self.webhook
	local json_payload = http.service:JSONEncode(self.payload)
	
	--regular send json payload
	if #self.attachments == 0 then
		return http.post(
			quick_to_url(webhook),
			{['Content-Type'] = 'application/json'},
			json_payload
		)
	end
	
	-- else, we need to send a mutlipart form data request
	local mutlipart = MultipartFormData.new()
	
	local struct = mutlipart:add(http.service:JSONEncode(self.payload))
	struct.content_type = 'application/json'
	struct.content_disposition.name = 'payload_json'
	
	-- do attachments
	for i, v in self.attachments do
		v.content_disposition.name = `file[{i}]`
		table.insert(mutlipart.collection, v)
	end
	
	local body =  mutlipart:to_string()
	local boundary = mutlipart.boundary
	
	return http.post(
		quick_to_url(webhook),
		{['Content-Type'] = mutlipart:get_header_value()},
		body
	)
end

module.object.from.struct = compose(module.struct.to.buffer, module.object.new) :: (struct: struct) -> object
module.object.from.url = compose(module.struct.from.string, module.object.from.struct) :: (url: string) -> object

Class.make_proper_class(module.object, '@CHL>DiscordWebhook')

return module
