-- SPEC
export type protocol = 'rbxassetid' |
	'rbxasset' |
	'rbxthumb' |
	'rbxhttp' |
	'https' |
	'http'

-- CLASS
local Content = {}
local ContentProvider = game:GetService('ContentProvider')

Content.contentProvider = ContentProvider

Content.getComponents = function(s: string) : (protocol?, string?)
	local p, st = s:match('(.-)://(.*)')

	return p, st
end

return Content
