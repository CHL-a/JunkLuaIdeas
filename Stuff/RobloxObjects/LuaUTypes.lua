local module = {}

function same(x)return x end
function disguise<A>(x: any) : A return same(x) end

module.assertify = function<A>(val: A?): A return same(val)end
module.disguise = disguise

--// !!! subjected to change because this way is terrible because intersection operation 
--// conflicts with metatmethods
export type __legacyObject<metamethods> = typeof(
	setmetatable({},disguise{} :: metamethods)
)

return module
