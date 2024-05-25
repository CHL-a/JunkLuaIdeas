local Objects = game:GetService('ReplicatedStorage').Objects

local Map = require(Objects["@CHL/Map"])

type map<I,V> = Map.simple<I,V>

export type object<A> = {
	Name: string;
	UserId: number;
	
	Get: (self: object<A>, default: A?, no_get_async: boolean?) -> A;
	Set: (self: object<A>, value: A) -> ();
	GetTable: <I,V>(default: map<I, V>) -> map<I, V>;
	Save: (self: object<A>) -> ();
}

return true
