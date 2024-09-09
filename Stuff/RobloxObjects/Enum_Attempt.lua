local Objects = script.Parent

local Map = require(Objects["@CHL/Map"])

module = {}

EnumItem = {}

export type enum_item<A> = typeof(
	setmetatable(
		{} :: {
			value: A;
			number_value: number;
		},
		EnumItem
	)
)

export type enum<INTERSECTION, MAP> = {
	intersection: INTERSECTION;
	enum_items: MAP
}

disguise = require(Objects.LuaUTypes).disguise

function EnumItem.new<T>(value: T, n: number): enum_item<T>
	return disguise(setmetatable({
		value = value;
		number_value = n
	}, EnumItem))
end

function EnumItem:equals<A>(other: number | A | enum_item<A>): boolean
	return self == other or self.value == other or self.number_value == other
end

function EnumItem.__eq<A>(self: enum_item<A>, other: enum_item<A>)
	return self.value == other.value and self.number_value == other.number_value
end

function module.new<I,M>(l: {I}): enum<I,M>
	local self: enum<I, M> = disguise(setmetatable({}, module))
	
	self.enum_items = disguise{}
	
	for i = 1, #l do
		if l[i]==nil then continue; end
		disguise(self).enum_items[l[i]] = EnumItem.new(l[i], i)
	end
	
	return self
end

EnumItem.__index = EnumItem;

return module
