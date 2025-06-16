local Map = require('./@CHL>Map')

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

export type enum<UNION, MAP> = {
	union: UNION;
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

function module.new<U,M>(l: {U}): enum<U,M>
	local self: enum<U, M> = disguise(setmetatable({}, module))
	
	self.enum_items = disguise{}
	
	for i = 1, #l do
		if l[i]==nil then continue; end
		disguise(self).enum_items[l[i]] = EnumItem.new(l[i], i)
	end
	
	return self
end

EnumItem.__index = EnumItem;

--##########################################################################################
--##########################################################################################
--##########################################################################################

export type default_types<A> = A | number | string

module.default_enum = {}

function module.default_enum.enumify<A>(value: default_types<A>, parent: Enum): A
	if type(value) == 'number' then
		value = disguise(parent):FromValue(value)
	elseif type(value) == 'string' then
		value = disguise(parent):FromName(value)
	end
	
	return disguise(value)
end

return module
