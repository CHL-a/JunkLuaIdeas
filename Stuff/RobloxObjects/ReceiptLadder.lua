local Objects = game:GetService('ReplicatedStorage').Objects
local Class = require(Objects.Class)
local LadderFunction = require(Objects["@CHL/LadderFunction"])

export type receipt = {
	CurrencySpent: number;
	PlaceIdWherePurchased: number;
	PlayerId: number;
	ProductId: number;
	PurchaseId: string;
}
export type object = Class.subclass<LadderFunction.object<receipt>>

Ladder = {}

function Ladder.new(): object return LadderFunction.Ladder.new():__inherit(Ladder)end

function Ladder.call(self: object, reciept: receipt)
	for i, v in next, self.rungs do
		local results = {v(reciept)}
		
		local value = results[1]
		
		if value == 'continue' then continue;
		elseif value == 'end' then return unpack(results, 2)
		elseif typeof(value) == 'EnumItem' 
			and value.EnumType == Enum.ProductPurchaseDecision then return value
		else
			error(`Attempting to climb ladder with invalid return: Expected: rung_type\z
				, got: {results[1]}, at i={i}`)
		end
	end
end

Ladder.__index = Ladder
Ladder.className = '@CHL/ReceiptLadder'

local module = {}

module.Ladder = Ladder

return module
