export type object<T, U...> = {
	consume: (self: object<T, U...>, T, U...)->();
}

module = {}
disguise = require('./LuaUTypes').disguise

module.void = {consume=disguise} :: object<any>
module.print = {consume=print} :: object<any>

return module
