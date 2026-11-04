--[[
	Sources: 
	 * https://www.alg0.dev/lz77
	 * https://en.wikipedia.org/wiki/LZ77_and_LZ78#Pseudocode
	 * https://abacktools.com/tools/compress/analyzers/lz77-compression-visualizer

	compresses based on repeated patterns from a window, window size varies but has a max

	window start
	|
	|   cursor
	|   |
	v   v
	ABCDABC
	--- ---
	^   ^
	matches that'll probably be listed, as offset = 4, length = 3
]]

local Iterator = require('./@CHL>Iterator')
local StringUtils = require('./@CHL>StringUtils')
local Class = require('./Class')
local Object = require('./Object')
local DoubleLinkedList = require('./@CHL>DoubleLinkedList')
local Dash = require('./@roblox>Dash')
local module = {}

type dl_list<T> = DoubleLinkedList.object<T>
export type byte_iterator = StringUtils.byte_iterator

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

export type compressor_struct = {
	offset: number;
	length: number;
	next: number;
}

compressor_struct = {}

function compressor_struct.to_string(self: compressor_struct): string
	return `<offset={self.offset}, length={self.length}, next={self.next or 'IMPLICIT_NIL'}>`
end

module.compressor_struct = compressor_struct

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

export type compressor = {
	iterator: byte_iterator;
	window_size: number;
	preceding_window: dl_list<number>;
	succeeding_window: dl_list<number>;
	
	destroy: (self: compressor) -> ();
} & Iterator.simple<compressor_struct>

compressor = {}

function compressor.new(iterator: byte_iterator, window_size: number?): compressor
	local self: compressor = Object.simple.new(compressor)
	
	self.iterator = iterator
	self.window_size = window_size
	self.preceding_window = DoubleLinkedList.new()
	self.succeeding_window = DoubleLinkedList.new()
	
	if iterator:can_proceed() then
		self.succeeding_window:insert(1, iterator:proceed())
	end
	
	return self
end

function compressor.can_proceed(self: compressor)
	return self.iterator:can_proceed() or not self.succeeding_window:is_empty()
end

function compressor.proceed(self: compressor)
	local succeeding_window = self.succeeding_window
	local preceding_window = self.preceding_window
	local preceding_forward = self.preceding_window:get_forward_iterator()
	local iterator = self.iterator
	local long = 0
	local current_offset = preceding_window.size
	local offset = 0
	
	while preceding_forward:can_proceed() do
		local window_matcher = DoubleLinkedList.forward_iterator.new(preceding_forward.current)
		local cursor_matcher = succeeding_window:get_forward_iterator()
		local window_value, cursor_value = window_matcher.current and window_matcher.current.value, cursor_matcher.current and cursor_matcher.current.value
		local length = 0
		
		while window_value and window_value == cursor_value do
			length += 1
			
			if window_matcher:can_proceed() then
				window_matcher:proceed()
			end
			
			if cursor_matcher:can_proceed() then
				if not cursor_matcher.current.next and iterator:can_proceed() then
					succeeding_window:insert_last(iterator:proceed())
				end
				
				cursor_matcher:proceed()
			end
			
			window_value, cursor_value = window_matcher.current and window_matcher.current.value, cursor_matcher.current and cursor_matcher.current.value
		end
		
		if length > long then
			long = length
			offset = current_offset
		end
		
		current_offset -= 1
		preceding_forward:proceed()
	end
	
	local result = {}
	result.offset = offset
	result.length = long
	
	for i = 1, long do
		preceding_window:insert_last(succeeding_window:remove(1))
	end
	
	if not succeeding_window:is_empty() then
		result.next = succeeding_window:remove(1)
		
		preceding_window:insert_last(result.next)
	end
	
	while self.window_size and preceding_window.size > self.window_size do
		preceding_window:remove(1)
	end
	
	if iterator:can_proceed() then
		succeeding_window:insert_last(iterator:proceed())
	end
	
	return result
end

function compressor.destroy(self: compressor)
	self.preceding_window:destroy()
	self.succeeding_window:destroy()
end

Dash.promise:expect()
compose = Dash.compose

compressor.from = {}
compressor.from.string = compose(StringUtils.iterator.byte.new, compressor.new) :: (string) -> (compressor)

Class.make_proper_class(compressor, '@CHL>LZ77>Compressor')

module.compressor = compressor

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

export type decompressor = {
	iterator: Iterator.simple<compressor_struct>;
	window_size: number;
	preceding_window: dl_list<number>;
	forward_iterator: DoubleLinkedList.forward_iterator<number>;
	
	populate_window: (self: decompressor) -> ();
	destroy: (self: decompressor) -> ();
} & Iterator.simple<number>

decompressor = {}

function decompressor.new(iterator: Iterator.simple<compressor_struct>, window_size: number?): decompressor
	local self: decompressor = Object.simple.new(decompressor)
	
	self.iterator = iterator
	self.window_size = window_size
	self.preceding_window = DoubleLinkedList.new()
	
	return self
end

function decompressor.can_proceed(self: decompressor): boolean
	return self.iterator:can_proceed() or self.forward_iterator and self.forward_iterator:can_proceed()
end

function decompressor.populate_window(self: decompressor): number
	local iterator = self.iterator
	
	if not self.iterator:can_proceed() then return end
	
	local preceding_window = self.preceding_window
	
	while self.window_size and self.window_size < preceding_window.size do
		preceding_window:remove(1)
	end
	
	local struct = iterator:proceed()
	
	if struct.length ~= 0 then
		local start_node = preceding_window:node_at(-struct.offset)
		
		local struct_forward = DoubleLinkedList.forward_iterator.new(start_node)
		
		for i = 1, struct.length do
			preceding_window:insert_last(struct_forward:proceed().value)
		end
	end
	
	if struct.next then
		preceding_window:insert_last(struct.next)
	end
end

function decompressor.proceed(self: decompressor): number
	if not self.forward_iterator then
		self:populate_window()
		self.forward_iterator = self.preceding_window:get_forward_iterator()
	end
	
	if self.forward_iterator.current and not self.forward_iterator.current.next then
		self:populate_window()
	end
	
	return self.forward_iterator:proceed().value
end

function decompressor.destroy(self: decompressor)
	self.preceding_window:destroy()
end

Class.make_proper_class(decompressor, '@CHL>LZ77>Decompressor')

module.decompressor = decompressor

--########################################################################################################################################################################
--########################################################################################################################################################################
--########################################################################################################################################################################

return module
