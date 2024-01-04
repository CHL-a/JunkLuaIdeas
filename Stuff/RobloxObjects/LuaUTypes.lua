--// metatable indices
type __metatableIndices = '__index' |'__newindex' | '__call' | '__concat' | 
	'__unm' | '__add' | '__sub' | '__mul' | '__div' | '__idiv' | '__mod' | 
	'__pow' | '__tostring' | '__metatable' | '__eq' | '__lt' | '__le' | 
	'__mode' | '__gc' | '__len' | '__iter'
export type metatableIndices = __metatableIndices

local module = {}

function same<A...>(...: A...): A... return ... end
function disguise<A...>(...: any) : A... return same(...) end
function empty()end

local a: string = disguise()

--// metatable type
type __binaryOp<__self> = (<__in, __out>(__self, __in) -> __out)?;
type __logicalOp<__self> = (<__in>(__self, __in) -> any?)?

type __metatable<__self> = typeof({
	__index = disguise() :: (
	{[any]: any} | -- needs work
		<I,V>(__self, I) -> V
	)?;
	__newindex = disguise() :: (<I, V>(__self, I, V) -> nil)?;
	__call = disguise() :: (<__in..., __out...>(__self, __in...) -> __out...)?;
	__concat = disguise() :: __binaryOp<__self>;
	__unm = disguise() :: (<A>(__self) -> A)?;
	
	__add = disguise() :: __binaryOp<__self>;
	__sub = disguise() :: __binaryOp<__self>;
	__mul = disguise() :: __binaryOp<__self>;
	__div = disguise() :: __binaryOp<__self>;
	__idiv = disguise() :: __binaryOp<__self>;
	
	__mod = disguise() :: __binaryOp<__self>;
	__pow = disguise() :: __binaryOp<__self>;
	__tostring = disguise() :: ((__self) -> string)?;
	__metatable = disguise() :: any?;
	__eq = disguise() :: __logicalOp<__self>;

	__lt = disguise() :: __logicalOp<__self>;
	__le = disguise() :: __logicalOp<__self>;
	__mode = disguise() :: ('k' | 'v' | 'kv')?; -- needs check
	__len = disguise() :: ((__self) -> number)?;
	__iter = disguise() :: (<__out...>(__self) -> () -> __out...)?
}
-- :: {[__metatableIndices]: any}
)
export type metatable<__self> = __metatable<__self>

--// theoretical object
--// !!! subjected to change because this way is terrible because intersection 
--// operation 
--// conflicts with metatmethods, so this is more like a temproary solution
export type __legacyObject<metamethods> = typeof(
	setmetatable({},disguise{} :: metamethods)
)

--// methods
module.assertify = function<A>(val: A?): A return disguise(val)end
module.disguise = disguise
module.same = same
module.empty = empty

return module
