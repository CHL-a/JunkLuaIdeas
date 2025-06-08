local Objects = script.Parent
local Dash = require('./@CHL>DashSingular')

export type pages<A> = {
	GetCurrentPage: (self: pages<A>)->A;
} & Pages

local module = {}

insert = table.insert
disguise = require('./LuaUTypes').disguise

--######################################################################################
--######################################################################################
--######################################################################################

local Iterator = require('./@CHL>Iterator')
local Class = require('./Class')

export type page_base<A> = {
	current_value: A
} & pages<A>
  & Class.subclass<Iterator.object<A, ()>>

PagesBase = {}

function PagesBase.new<A>(): page_base<A>
	local self: page_base<A> = Iterator.new():__inherit(PagesBase)

	return self
end

function PagesBase.GetCurrentPage<A>(self: page_base<A>)
	return self.current_value
end

function PagesBase.AdvanceToNextPageAsync<A>(self: page_base<A>)
	if self.IsFinished then return;end

	self.current_value = self:proceed()
	self.IsFinished = not self:canProceed()
end

function PagesBase.__index<A>(self: page_base<A>, i: string)
	if i == 'IsFinished' then
		self.IsFinished = not self:canProceed()
		return self.IsFinished
	elseif i == 'current_value' then
		if not rawget(self, i) and not self.IsFinished then
			self.current_value = self:proceed()
		end
	end

	return PagesBase[i] or self.__super[i]
end

Class.makeProperClass(PagesBase, '@CHL>Pages>Base')

module.base = PagesBase

--######################################################################################
--######################################################################################
--######################################################################################

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

--######################################################################################
--######################################################################################
--######################################################################################

return module
