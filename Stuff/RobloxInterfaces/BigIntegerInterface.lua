--[[
	Referal = https://devforum.roblox.com/t/201-biginteger-safely-store-and-represent-values-over-2%E2%81%B5%C2%B3/587199
]]

local LuaUTypes = require(script.Parent.LuaUTypes)
local disguise = LuaUTypes.disguise

type __methods = {
	abs: (value: __object) -> __object;
	band: (left: __object, right: __object) -> __object;
	bor: (left: __object, right: __object) -> __object;
	bnot: (left: __object, right: __object) -> __object;
	bxor: (left: __object, right: __object) -> __object;
	
	shl: (value: __object, displacement: number) -> __object;
	shr: (value: __object, displacement: number) -> __object;
	divrem: (left: __object, right: __object) -> (__object, __object);
	log: (value: __object, base: number?) -> number;
	log2: (value: __object) -> number;
	
	log8: (value: __object) -> number;
	log10: (value: __object) -> number;
	log12: (value: __object) -> number;
	log16: (value: __object) -> number;
	iseven: (value: __object) -> boolean;
	
	ispoweroftwo: (value: __object) -> boolean;
	max: (value: __object, ...__object) -> __object;
	min: (value: __object, ...__object) -> __object;
	sum: (value: __object, ...__object) -> __object;
	clamp: (value: __object, min: __object, max: __object) -> __object;
	
	sign: (value: __object) -> number;
	copysign: (value: __object, sign: __object) -> __object;
	compare: (left: __object, right: __object) -> number;
	factorial: (value: __object) -> __object;
	gcd: (value: __object) -> __object;
	
	todouble: (value: __object) -> number;
	tostring: (value: __object, __tostringOptions) -> string;
	isbiginteger: (value: __object) -> boolean;
}

type __tostringOptions = {
	useGrouping: boolean;
	decimalSymbol: string? | '.';
	groupSymbol: string?;
	minimumGroupingDigits: number?;
	minimumIntegerDigits: number?;
	
	notation: "standard" | 'scientific' | 'engineering';
	numberingSystem: string? | 'latn';
}

type __binaryOp<__self> = (__self, __self) -> __self
type __logicalOp<__self> = (__self, __self) -> any?

type __object = LuaUTypes.__legacyObject<{
	__index : __methods;
	__add : __binaryOp<__object>;
	__sub : __binaryOp<__object>;
	__mul : __binaryOp<__object>;
	__div : __binaryOp<__object>;
	
	__mod : __binaryOp<__object>;
	__pow : __binaryOp<__object>;
	__eq : __logicalOp<__object>;
	__le : __logicalOp<__object>;
	__lt : __logicalOp<__object>;
}>

type __class = {
	new: (any) -> __object;
	
	zero: __object;
	one: __object;
	minusone: __object;
} & __methods

export type object = __object;
export type class = __class;
export type tostringOptions = __tostringOptions

return true
