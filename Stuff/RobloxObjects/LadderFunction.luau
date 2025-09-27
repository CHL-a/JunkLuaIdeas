local Object = require('./Object')

export type rung_type = 'continue' | 'end'
export type rung_result = {
	rung_type: rung_type;
	values: {any};
};

export type rung_function<params...> = (params...) -> rung_result

export type rung<params...> = {
	climb: (self: rung<params...>, params...)->rung_result
}

export type object<init_params..., implied_returns...> = {
	rungs: {rung<...any>|rung_function<...any>};
	call: (self: object<init_params..., implied_returns...>, init_params...)->(implied_returns...)
} & Object.object_inheritance

--########################################################################################
--########################################################################################
--########################################################################################

local module = {}

disguise = require('./LuaUTypes').disguise

RungResult = {}

function RungResult.new<returns...>(rung_type: rung_type, ...: returns...): rung_result
	return {
		rung_type = rung_type;
		values = {disguise(...)}
	}
end

module.rung_result = RungResult

--########################################################################################
--########################################################################################
--########################################################################################

Ladder = {}

function Ladder.new<init_params...>(): object<init_params...> 
	local self = Object.simple.new(Ladder)
	self.rungs = {}
	return self
end

function Ladder.call<init_params...,Returns...>(self: object<init_params...>, ...: init_params...)
	local params = {disguise(...)}
	
	for i, v in self.rungs do
		local rung_result
		
		if typeof(v) == 'function' then
			rung_result = v(unpack(params))
		else
			rung_result = v:climb(unpack(params))
		end
		
		assert(typeof(rung_result) == 'table')
		
		local rung_type: rung_type = rung_result.rung_type
		
		if rung_type == 'continue' then
			params = rung_result.values
			continue
		elseif rung_type == 'end' then
			return unpack(rung_result.values)
		else
			print(rung_result)
			error(`Attempting to climb ladder with invalid return ^`)
		end
	end
end

Ladder.__call = Ladder.call
Ladder.__index = Ladder
Ladder.className = '@CHL>LadderFunction'

module.ladder = Ladder

return module
