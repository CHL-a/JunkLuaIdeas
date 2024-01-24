--// TYPES
local Objects = script.Parent
type __object<A> = {
	instanceReferral: A;
	
	objectIndex: (self:__object<A>, i: string) -> any;
} & A
export type object<A> = __object<A>

--// MAIN
local module = {}
local LuaUTypes = require(Objects.LuaUTypes)

disguise = LuaUTypes.disguise

-- needs testing
module.__index = function<A>(self: __object<A>, i: string, isObject: boolean?)
	local __s = disguise(self)
	
	if nil ~= __s[i] or isObject then
		return __s[i]
	elseif nil ~= module[i] then
		return module[i]
	end
	
	return __s.instanceReferral[i]
end

function module.new<A>(a: A)
	local self: __object<A> = disguise(setmetatable({}, module))
	
	self.instanceReferral = a
	
	return self
end

module.objectIndex = function<A>(self: __object<A>, i: string)
	return module.__index(self, i, true)
end

return module
