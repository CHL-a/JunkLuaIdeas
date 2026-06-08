local module = {}

dominions = {}

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

-- very easily accessable version of an icon since these ones are always accessable, albiet, the domain is rather small

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

dominions.stable = {}

export type stable_struct = {
	Image: Content;
	ImageRectOffset: Vector2;
	ImageRectSize: Vector2;
}

function dominions.stable.get(class: string): stable_struct
	local result = game:GetService('StudioService'):GetClassIcon(class)
	
	result.Image = Content.fromUri(result.Image)
	
	return result
end

--##############################################################################################################################################
--##############################################################################################################################################
--##############################################################################################################################################

module.dominions = dominions

return module
