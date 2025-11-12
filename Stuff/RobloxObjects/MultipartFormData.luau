--[[
	This file is in context of http messaging
	
	References:
	https://datatracker.ietf.org/doc/html/rfc7578#page-4
]]

local Object = require('./Object')
local Class = require('./Class')
local Radix = require('./@CHL>Radix')
local Map = require('./@CHL>Map')

type dict<A> = Map.dictionary<A>

export type part_struct = {
	content: string;
	content_disposition:{
		name: string;
		filename: string?;
	};
	content_type: string;
}

export type object = {
	collection: {part_struct};
	boundary: string?;
	
	add: (self: object, string)->part_struct;
	add_buffer: (self: object, buffer)->part_struct;
	
	-- strictly speaking, only returns a boundary without a newline
	pick_boundary: (self: object) -> string;
	to_string: (self: object) -> string;
	get_header_value: (self: object)->string;
}

local module = {}

alphanumeric = Radix.charRadix.alphanumeric
disguise = require('./LuaUTypes').disguise
tinsert = table.insert

function module.new(): object
	local self: object = Object.simple.new(module)
	
	self.collection = {}
	
	return self
end

function module.add(self: object, str: string)
	local result: part_struct = {
		content = str;
		content_disposition = {
			-- currently, Content-Disposition is only form-data
			name = `data{#self.collection + 1}`
		};
		content_type = 'text/plain';
		headers = {};
	}
	
	table.insert(self.collection, result)
	
	return result
end

function module.add_buffer(self: object, buff: buffer)
	local str = buffer.tostring(buff)
	
	return self:add(str)
end

function module.pick_boundary(self: object)
	local i = 0
	local prefix = disguise(module).boundary_prefix
	
	while true do
		local str = prefix .. alphanumeric:fromDecimal(i)
		
		-- check if str is already in collection
		local is_found = false
		
		for _, v in self.collection do
			if v.content:find(str) then
				is_found = true
				break
			end
		end
		
		if not is_found then
			return str
		end
		
		i += 1
	end
end

function module.to_string(self: object)
	if not self.boundary then
		self.boundary = self:pick_boundary()
	end
	
	local boundary = self.boundary
	
	
	boundary = '--' .. boundary
	
	local batch = {boundary}
	
	for _, v in self.collection do
		local header_clone = {}
		
		header_clone['Content-Type'] = v.content_type
		header_clone['Content-Disposition'] = `form-data; name="{v.content_disposition.name}"`
		
		if v.content_disposition.filename then
			header_clone['Content-Disposition'] ..= `; filename="{v.content_disposition.filename}"`
		end
		
		tinsert(batch, '\r\n')
		
		for i, v in header_clone do
			tinsert(batch, `{i}: {v}\r\n`)
		end
		
		tinsert(batch, `\r\n{v.content}\r\n{boundary}`)
	end
	
	tinsert(batch, '--')
	
	return table.concat(batch)
end

function module.get_header_value(self: object)
	return `{module.mime}; boundary={self.boundary}`
end

module.mime = 'multipart/form-data'
module.boundary_prefix = '------MultipartBoundary'

Class.makeProperClass(module, '@CHL>MultipartFormData')

return module
