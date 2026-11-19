local Iterator = require('./@CHL>Iterator')

type iterator<T, U...> = Iterator.simple<T, U...>

export type object<T, U...> = {
	consume: (self: object<T, U...>, T, U...)->();
	dump: (self: object<T, U...>, iterator<T, U...>) -> ();
}

module = {}
disguise = require('./LuaUTypes').disguise

function module.dump(consumer, iterator)
	while iterator:can_proceed() do
		consumer:consume(iterator:proceed())
	end
end

module.void = {consume=disguise; dump=module.dump} :: object<any>
module.print = {consume=print; dump=module.dump} :: object<any>

return module
