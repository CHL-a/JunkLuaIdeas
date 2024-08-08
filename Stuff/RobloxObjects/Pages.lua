local Objects = script.Parent
local Dash = require(Objects["@CHL/DashSingular"])

export type pages<A> = {
	GetCurrentPage: (self: pages<A>)->A
} & Pages

local module = {}

insert = table.insert
disguise = require(Objects.LuaUTypes).disguise

module.imprint = {}

function module.iterator<A>(pages: pages<A>): () -> (number, {A})
	local i = 0
	local is_null = false

	return function()
		if is_null then return end
		i += 1
		local v = pages:GetCurrentPage()

		if not pages.IsFinished then
			pages:AdvanceToNextPageAsync()
		else
			is_null = true
		end

		return i, v
	end
end

function module.iterator_1d<A>(pages: pages<A>): () -> (number, A)
	local i = 0
	local j = 0
	local now

	return function()
		if not now or not now[j+1] then
			if now and not now[j+1] then
				if pages.IsFinished then return end

				pages:AdvanceToNextPageAsync()
			end

			now = pages:GetCurrentPage()
			j = 0
		end

		i += 1
		j += 1

		return i, now[j]
	end
end

function module.imprint.to_array<A>(result: {{A}}, pages: pages<A>): {{A}}
	for _, v in module.iterator(pages) do insert(result, v)end
	return result
end

function module.imprint.to_1d_array<A>(result: {A}, pages: pages<A>): {A}
	for _, v in module.iterator_1d(pages) do insert(result) end
	return result
end

function module.to_arrays<A>(pages:pages<A>):{{A}}return module.imprint.to_array({},pages)end
function module.to_1d_array<A>(pages:pages<A>):{A}return module.imprint.to_1d_array({}, pages)end

return module
