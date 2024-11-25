export type model<A> = {
	--[[
		Takes in A, returns root instances
	]]
	build: (self: model<A>, A) -> {Instance}
}

return true
