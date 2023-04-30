--[[
	Just so we're clear, this is node, as in the object concept and not NodeJS.
]]

export type GeneralTreeNode = {
	children: {GeneralTreeNode}
}