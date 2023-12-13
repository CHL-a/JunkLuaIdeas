--[[
	From: https://github.com/stravant/goodsignal/blob/master/src/init.lua
--]]

type __module = {
	new: <__out...>() -> __object<__out...>;
}
export type module = __module

type __connection = {
	Disconnect: (self: __connection) -> nil
}
export type connection = __connection

type __object<__out...> = {
	Connect: (self:__object<__out...>, fn: (...any) -> (__out...)) -> __connection;
	DisconnectAll: (self: __object<__out...>) -> nil;
	Fire: (self:__object<__out...>, __out...) -> nil;
	Wait: (self:__object<__out...>) -> (__out...);
	Once: (self:__object<__out...>, fn: (...any) -> (__out...)) -> __connection;
}
export type object<out...> = __object<out...>

return true
