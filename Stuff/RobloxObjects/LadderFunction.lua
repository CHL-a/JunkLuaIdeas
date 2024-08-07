local Objects = script.Parent
local Object = require(Objects.Object)

export type rung_type = 'continue' | 'end'
export type rung<Params..., Returns...> = {
	climb: (self: rung<Params..., Returns...>, Params...)->(rung_type, Returns...);
} & Object.object_inheritance
export type object<init_params...> = {
	rungs: {rung<...any,...any>|(...any)->(rung_type, ...any)};
	call: <Returns...>(init_params...)->(Returns...)
} & Object.object_inheritance

--########################################################################################
--########################################################################################
--########################################################################################

Ladder = {}

function Ladder.new<init_params...>(): object<init_params...> 
	local self = Object.from.class(Ladder)
	self.rungs = {}
	return self
end

function Ladder.call<init_params...,Returns...>(self: object<init_params...>, ...: init_params...)
	for i, v in next, self.rungs do
		local results = {v(...)}
		
		if results[1] == 'continue' then continue;
		elseif results[1] == 'end' then return unpack(results, 2)
		else
			error(`Attempting to climb ladder with invalid return: Expected: rung_type\z
				, got: {results[1]}, at i={i}`)
		end
	end
end

Ladder.__index = Ladder
Ladder.className = '@CHL/LadderFunction'

local module = {}

module.Ladder = Ladder

return module
