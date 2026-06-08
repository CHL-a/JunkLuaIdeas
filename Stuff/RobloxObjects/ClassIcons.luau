local module = {}

dominions = {}

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

-- very easily accessable version of an icon since these ones are always 
-- accessable via content folder, albiet, the domain is rather small

export type insertable_size = '' | '@2x' | '@3x'
export type insertable_color_theme = 'Dark' | 'Light'

insertable = {}
insertable.directory = 'rbxasset://studio_svg_textures/Shared/InsertableObjects/'

function insertable.get(class: string, size: insertable_size?, theme: insertable_color_theme?): Content
	local size = size or ''
	local theme = theme or 'Dark'
	
	local uri = `{insertable.directory}{theme}/Standard/{class}{size}.png`
	return Content.fromUri(uri)
end

dominions.insertable = insertable

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

-- another method of fetching icon, however this one is more studio based, and
-- therefore requires plugin security

local PluginToolset = require('./@CHL>PluginToolset')

dominions.studio = {}

export type studio_struct = {
	Image: Content;
	ImageRectOffset: Vector2;
	ImageRectSize: Vector2;
}

function dominions.studio.get(class: string): studio_struct
	if not PluginToolset.is_plugin_space():expect() then
		warn('attempted to fetch studio icon outside of plugin space')
		return
	end
	
	local result = game:GetService('StudioService'):GetClassIcon(class)
	
	result.Image = Content.fromUri(result.Image)
	
	return result
end

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

module.dominions = dominions

return module
