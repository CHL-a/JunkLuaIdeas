export type pages<T> = {
	IsFinished: boolean;
	AdvanceToNextPageAsync: (self: pages<T>) -> ();
	GetCurrentPage: (self: pages<T>)->{T};
} & Pages

local module = {}

insert = table.insert
disguise = require('./LuaUTypes').disguise

--######################################################################################
--######################################################################################
--######################################################################################

local Class = require('./Class')
local Object = require('./Object')
local Iterator = require('./@CHL>Iterator')

type iterator_simple<T> = Iterator.simple<T, ()>

export type pages_iterator<T> = {
	pages: pages<T>;
} & iterator_simple<T>

pages_iterator = {}

function pages_iterator.new<T>(pages: pages<T>): pages_iterator<T>
	local self: pages_iterator<T> = Object.simple.new(pages_iterator)
	
	self.pages = pages
	
	return self
end

function pages_iterator.can_proceed<T>(self: pages_iterator<T>) : boolean return not self.pages.IsFinished end
function pages_iterator.proceed<T>(self: pages_iterator<T>): {T}
	local pages: pages<T> = self.pages
	
	if pages.IsFinished then return end
	
	local result = pages:GetCurrentPage()
	
	pages:AdvanceToNextPageAsync()
	
	return result
end

Class.make_proper_class(pages_iterator, '@CHL>Pages>Iterator')

module.pages_iterator = pages_iterator

--######################################################################################
--######################################################################################
--######################################################################################

--[[
	Note: mock pages are for faking data
--]]
export type mock_pages<T> = {
	iterator: iterator_simple<{T}>;
	current_value: {T};
} & pages<T>
  & iterator_simple<T>

local Dash = require('@game/ReplicatedStorage/Objects/@roblox>Dash')

Dash.promise:await()

compose = Dash.compose

mock_pages = {}
mock_pages.from = {}

function mock_pages.new<T>(iterator: iterator_simple<T>): mock_pages<T>
	local self: mock_pages<T> = Object.simple.new(mock_pages)
	
	self.iterator = iterator
	self.IsFinished = not iterator:can_proceed()
	
	if not self.IsFinished then
		self.current_value = iterator:proceed()
	end
	
	return self
end

mock_pages.from.pages = compose(pages_iterator.new, mock_pages.new) :: <T>(pages: pages<T>) -> mock_pages<T>

function mock_pages.GetCurrentPage<A>(self: mock_pages<A>) return self.current_value end

function mock_pages.AdvanceToNextPageAsync<A>(self: mock_pages<A>)
	if disguise(self).IsFinished then return end
	
	self.current_value = self.iterator:proceed()
	self.IsFinished = not self.iterator:can_proceed()
end

Class.make_proper_class(mock_pages, '@CHL>Pages>Base')

module.mock_pages = mock_pages

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
