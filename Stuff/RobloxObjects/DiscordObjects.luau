--[[
	Holds a collection of discord object types
	
	currently incomplete
]]

export type embed_footer = {
	text: string;
	icon_url: string?; -- url of footer icon (only supports http(s) and attachments)
	proxy_icon_url: string?; -- a proxied url of footer icon
}

export type embed_image = {
	url: string;
	proxy_url: string?; -- a proxied url of the image
	width: number?;
}

export type embed_thumbnail = {
	url: string;
	proxy_url: string?;
	height: number?;
	width: number?;
}

export type embed_author = {
	name: string;
	url: string?;
	icon_url: string?;
	proxy_icon_url: string?;
}

export type embed_field = {
	name: string;
	value: string;
	inline: boolean?; -- whether or not this field should display inline
}

export type embed = {
	title: string?;
	--type	string?	type of embed (always “rich” for webhook embeds)
	description: string?;
	url: string?;
	timestamp: string?; -- of ISO8601 format
	color: number?; -- int	rgb color code of the embed
	footer: embed_footer?; -- footer
	image: embed_image?; -- image
	thumbnail: embed_thumbnail?; -- thumbnail
	video: nil?;-- video
	provider: nil?; -- provider object
	author: embed_author?; -- author
	fields: {embed_field}; -- array of fields
}

local module = {}

return module
