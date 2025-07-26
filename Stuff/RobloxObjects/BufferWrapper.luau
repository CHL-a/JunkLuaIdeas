--// TYPES
local Objects = script.Parent

export type object = {
	referral: buffer;

	writeBytes: (self: object, offset: number, ...number) -> ();
	getBytes: (self: object, offset: number, len: number?) -> {number};
	readFloat: (self: object, offset: number) -> number;
	writeFloat: (self: object, offset: number, val: number) -> ();
	readDouble: (self: object, offset: number) -> number;
	writeDouble: (self: object, offset: number, val: number) -> ();
	swapBytes: (self: object, offsetI: number, offsetJ: number) -> ();

	__len: (self: object) -> number;
	len: (self: object) -> number;
	__tostring: (self: object) -> string;
	toString: (self: object, sType: number?, ...any) -> string;
	readi8: (self: object, offset: number) -> number;
	readu8: (self: object, offset: number) -> number;
	readi16: (self: object, offset: number) -> number;
	readu16: (self: object, offset: number) -> number;
	readi32: (self: object, offset: number) -> number;
	readu32: (self: object, offset: number) -> number;
	readf32: (self: object, offset: number) -> number;
	readf64: (self: object, offset: number) -> number;
	writei8: (self: object, offset: number, val: number) -> ();
	writeu8: (self: object, offset: number, val: number) -> ();
	writei16: (self: object, offset: number, val: number) -> ();
	writeu16: (self: object, offset: number, val: number) -> ();
	writei32: (self: object, offset: number, val: number) -> ();
	writeu32: (self: object, offset: number, val: number) -> ();
	writef32: (self: object, offset: number, val: number) -> ();
	writef64: (self: object, offset: number, val: number) -> ();
	readstring: (self: object, offset: number, len: number) -> string;
	writestring: (self: object, offset: number, val: string, count: number?) -> ();
	copy: (self: object, fromOffset: number, to: buffer | object, toOffset: number?, 
		count: number?) -> ();
	fill: (self: object, offset: number, val: number, count: number?) -> ();
}

--// MAIN
local LuaUTypes = require('./LuaUTypes')
local Dash = require('./@CHL>DashSingular')
local Radix = require('./@CHL>Radix')
local Iterator = require('./@CHL>Iterator')
local Class = require('./Class')
local StringUtils = require('./@CHL>StringUtils')
local Math = require('./@CHL>Math')

module = {}
from = {}
raw_constructors = {}
disguise = LuaUTypes.disguise
compose = Dash.compose
hexUpper = Radix.charRadix.hexdecUpper
readu8 = buffer.readu8
len = buffer.len
insert = table.insert

function raw_constructors.bytes(...: number): buffer
	local n = select('#', ...)
	local b = buffer.create(n)
	for i = 1, n do
		local byte = select(i, ...)
		buffer.writeu8(b, i - 1, byte)
	end
	
	return b
end

function from.string(s: string): object return module.new(buffer.fromstring(s))end
function from.size(n: number): object return module.new(buffer.create(n))end

function module.new(b: buffer): object
	local self: object = disguise(setmetatable({}, module))
	self.referral = b

	return self
end

function enqueReferral(self: object, ...)return self.referral, ... end

function module.swapBytes(self: object, i: number, j: number)
	local t = self:readu8(i)
	self:writeu8(i, self:readu8(j))
	self:writeu8(j, t)
end

function module.writeBytes(self: object, offset: number, ...: number)
	for i = 1, select('#', ...) do
		local b = select(i, ...)
		self:writeu8(offset + i - 1, b)
	end
end

function module.getBytes(self: object, offset: number, len: number)
	len = len or 1

	local result = {}

	for i = 1, len do
		table.insert(result, self:readu8(offset + i - 1))
	end

	return result
end

function module.toString(self: object, sType: number?, ...)
	if not sType then return buffer.tostring(self.referral) end
	
	local len = self:len()
	local arg1 = ...
	
	if sType == 1 then
		local bytes = self:getBytes(0, len)

		for i = 1, len do
			bytes[i] = hexUpper:formatSequence(bytes[i], 2)
		end

		return table.concat(bytes, '_')
	elseif sType== 2 then
		--[[
		Sample:
		
		+--+----------------+
		|rw|0123456789ABCDEF|
		+--+----------------+
		|00|................|
		|10|................|
		|20|                |
		...
		]]
		local viewing_size = 0x100
		-- row_offset = arg1
		arg1 = arg1 or 0
		
		local row_len = Math.glass_div(viewing_size, 0x10)
		local rw_len = math.max(2, #hexUpper:formatSequence(len))
		
		local strings = {}
		local line_1 = `+{('-'):rep(rw_len)}+----------------+`
		
		-- this part is responsible for the header, based on the sample above
		strings[1] = line_1 .. '\n'
		strings[2] = `|{(' '):rep(rw_len - 2)}rw|0123456789ABCDEF|\n`
		strings[3] = strings[1]
		
		print(row_len)
		
		-- this part inserts to the table by row, starting with the index then content
		for r = 1, row_len do
			r -= 1
			insert(strings, `|{hexUpper:formatSequence(r, rw_len-1)}0|`)
			
			for c = 1, 0x10 do
				c -= 1
				
				local char = ' '
				local i = viewing_size * arg1 + r * 0x10 + c
				
				if i < len then
					local byte = self:readu8(i)
					
					char = string.char(byte)

					if not StringUtils.char.is_printable(char) then
						char = '.'
					end
				end
				
				insert(strings, char)
			end
			
			insert(strings,'|\n')
		end
		
		insert(strings, line_1)
		
		return table.concat(strings)
	elseif sType== 3 or sType == 4 then
		local viewing_size = 0x100
		-- row_offset = arg1
		--[[
		Sample:
		
		+--+-----------------------------------------------+
		|rw|00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F|
		+--+-----------------------------------------------+
		|00|xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx|
		|10|xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx|
		|20|xx xx xx xx xx xx xx xx xx xx xx xx xx xx      |
		...
		]]
		
		local row_len = Math.glass_div(viewing_size, 0x10)
		local rw_len = math.max(2, #hexUpper:formatSequence(len))
		local strs = {}
		local line_1 = `+{('-'):rep(rw_len)}+-----------------------------------------------+`
		
		strs[1] = line_1 .. '\n'
		strs[2] = `|{(' '):rep(rw_len - 2)}rw|00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F|\n`
		strs[3] = strs[1]
		
		-- explicit return because clamp will error
		if len == 0 then return table.concat(strs) end
		
		arg1 = math.clamp(arg1, 0, Math.glass_div(len, 0x100) - 1)
		
		for r = 1, row_len do
			r -= 1
			insert(strs, `|{hexUpper:formatSequence(arg1 * (viewing_size / 0x10) + r,rw_len-1)}0|`)

			for c = 1, 0x10 do
				c -= 1

				local set = '  '
				local i = viewing_size * arg1 + r * 0x10 + c

				if i < len then
					local byte = self:readu8(i)
					local char = string.char(byte)
					
					if sType == 4 and StringUtils.char.is_printable(char) then
						set = ` {char}`
					else
						set = hexUpper:formatSequence(byte, 2)
					end
					
				end

				insert(strs, set)
				
				if c == 0x0F then
					insert(strs, '|\n')
				else
					insert(strs, ' ')
				end
			end
		end
		
		insert(strs, line_1)
		return table.concat(strs)
	else error(`Bad sType: {sType}`)end
end

function module.copy(self: object, fromOffset: number, to: buffer | object, 
	toOffset: number?, count: number?)
	if typeof(to) == 'buffer' then
		return buffer.copy(self.referral, fromOffset, to, toOffset, count)
	end

	return self:copy(fromOffset, to.referral, toOffset, count)
end

-- primary_debugging
function module.debug_find_diff(op_1: object, op_2: object): (boolean, string?)
	local least = math.min(op_1:len(), op_2:len())
	local most = math.max(op_1:len(), op_2:len())
	if least == 0 and most ~= least then
		return false, `\n{op_1:toString(4)}\n{op_2:toString(4)}`
	end
	
	local i = 0
	
	while i < least do
		local i_th_byte_same = op_1:readu8(i) == op_2:readu8(i)
		
		if not i_th_byte_same then
			break
		end
		
		i+=1
	end
	if least == most and i == least then
		return true, 'operands are same'
	else
		local start_at = i // 0x100
		return false, (`start_at={start_at}\n{op_1:toString(4,start_at)}\n{op_2:toString(4,start_at)}`)
	end
end

module.readi8 = compose(enqueReferral, buffer.readi8)
module.readu8 = compose(enqueReferral, readu8)
module.readi16 = compose(enqueReferral, buffer.readi16)
module.readu16 = compose(enqueReferral, buffer.readu16)
module.readi32 = compose(enqueReferral, buffer.readi32)
module.readu32 = compose(enqueReferral, buffer.readu32)
module.readf32 = compose(enqueReferral, buffer.readf32)
module.readf64 = compose(enqueReferral, buffer.readf64)
module.writei8 = compose(enqueReferral, buffer.writei8)
module.writeu8 = compose(enqueReferral, buffer.writeu8)
module.writei16 = compose(enqueReferral, buffer.writei16)
module.writeu16 = compose(enqueReferral, buffer.writeu16)
module.writei32 = compose(enqueReferral, buffer.writei32)
module.writeu32 = compose(enqueReferral, buffer.writeu32)
module.writef32 = compose(enqueReferral, buffer.writef32)
module.writef64 = compose(enqueReferral, buffer.writef64)
module.readstring = compose(enqueReferral, buffer.readstring)
module.writestring = compose(enqueReferral, buffer.writestring)
module.fill = compose(enqueReferral, buffer.fill)
module.len = compose(enqueReferral, len)
module.__tostring = module.toString
module.__len = module.len
module.readFloat = module.readf32
module.writeFloat = module.writef32
module.readDouble = module.readf64
module.writeDouble = module.writef64
module.from = from
module.raw_constructors = raw_constructors

Class.makeProperClass(module, '@CHL/BufferWrapper')

--#####################################################################################
--#####################################################################################
--#####################################################################################

Temp = {}

Temp.temp = nil

function Temp.new(): object return module.from.size(8) end

function getTemp(): object
	if not Temp.temp then
		Temp.temp = Temp.new()
	end

	return Temp.temp
end

module.getTemp = getTemp

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type iterator = {
	referral: buffer;
	current: number;
} & Class.subclass<Iterator.object<number>>

BufferIterator = {}

function BufferIterator.init_simple(b: buffer)
	return BufferIterator.simple, b, -1
end

function BufferIterator.simple(b: buffer, current: number)
	current += 1
	if current >= len(b)then return;end
	return current, readu8(b, current)
end

function BufferIterator.new(_buffer: buffer, _current: number?)
	local self: iterator = Class.inherit(Iterator.new(), BufferIterator)
	self.referral = _buffer
	self.current = _current or 0
	
	return self
end

function BufferIterator.canProceed(self: iterator)
	return len(self.referral) > self.current
end

function BufferIterator.proceed(self: iterator)
	local byte = readu8(self.referral, self.current)
	self.current += 1
	return byte
end

Class.makeProperClass(BufferIterator, '@CHL/BufferWrapper/Iterator')
module.BufferIterator = BufferIterator

--#####################################################################################
--#####################################################################################
--#####################################################################################

export type stream = {
	referral: object;
	i: number;
	
	increment: (self: stream, i: number?)->();

	writeBytes: (self: stream, ...number) -> ();
	getBytes: (self: stream,  len: number?) -> {number};
	readFloat: (self: stream) -> number;
	writeFloat: (self: stream,  val: number) -> ();
	readDouble: (self: stream) -> number;
	writeDouble: (self: stream,  val: number) -> ();

	__len: (self: stream) -> number;
	len: (self: stream) -> number;
	readi8: (self: stream) -> number;
	readu8: (self: stream) -> number;
	readi16: (self: stream) -> number;
	readu16: (self: stream) -> number;
	readi32: (self: stream) -> number;
	readu32: (self: stream) -> number;
	readf32: (self: stream) -> number;
	readf64: (self: stream) -> number;
	writei8: (self: stream,  val: number) -> ();
	writeu8: (self: stream,  val: number) -> ();
	writei16: (self: stream,  val: number) -> ();
	writeu16: (self: stream,  val: number) -> ();
	writei32: (self: stream,  val: number) -> ();
	writeu32: (self: stream,  val: number) -> ();
	writef32: (self: stream,  val: number) -> ();
	writef64: (self: stream,  val: number) -> ();
	readstring: (self: stream,  len: number) -> string;
	writestring: (self: stream,  val: string, count: number?) -> ();
	fill: (self: stream,  val: number, count: number?) -> ();
}

Stream = {}

function Stream.new(r: object): stream
	return disguise(setmetatable({referral = r; i = 0}, Stream))
end

function stream_f_inc(n: number, method: (object, ...any)->any)
	return function(self: stream, ...)
		local result = method(self.referral, self.i, ...)
		self:increment(n)
		return result
	end
end

function stream_f_prx_call()
	return function(self: stream, ...)
		return self.referral, ...
	end
end

function stream_f_deprecated(s: string?)
	return function()
		error(s or 'Method is deprecated')
	end
end

function Stream.readstring(self: stream, len: number)
	local result = self.referral:readstring(self.i, len)
	self:increment(len)
	return result
end

function Stream.writestring(self: stream, val: string, count: number?)
	self.referral:writestring(self.i, val, count)
	self:increment(count or #val)
end

function Stream.getBytes(self: stream, len: number?)
	local result = self.referral:getBytes(self.i, len)
	self:increment(#result)
	return result
end

function Stream.writeBytes(self: stream, ...)
	self.referral:writeBytes(self.i, ...)
	self:increment(select('#', ...))
end

function Stream.fill(self: stream, val: number, count: number?)
	self.referral:fill(self.i, val, count)
	if count then
		self:increment(count)
	else
		self.i = self:len()
	end
end

function Stream.increment(self: stream, i: number)self.i+=(i or 1)end

Stream.copy = stream_f_deprecated()
Stream.len = compose(stream_f_prx_call, module.len)
Stream.readi8 = stream_f_inc(1, module.readi8)
Stream.readu8 = stream_f_inc(1, module.readu8)
Stream.readi16 = stream_f_inc(2, module.readi16)
Stream.readu16 = stream_f_inc(2, module.readu16)
Stream.readi32 = stream_f_inc(4, module.readi32)
Stream.readu32 = stream_f_inc(4, module.readu32)
Stream.readf32 = stream_f_inc(4, module.readf32)
Stream.readf64 = stream_f_inc(8, module.readf64)
Stream.writei8 = stream_f_inc(1, module.writei8)
Stream.writeu8 = stream_f_inc(1, module.writeu8)
Stream.writei16 = stream_f_inc(2, module.writei16)
Stream.writeu16 = stream_f_inc(2, module.writeu16)
Stream.writei32 = stream_f_inc(4, module.writei32)
Stream.writeu32 = stream_f_inc(4, module.writeu32)
Stream.writef32 = stream_f_inc(4, module.writef32)
Stream.writef64 = stream_f_inc(8, module.writef64)
Stream.__len = Stream.len
Stream.readFloat = Stream.readf32
Stream.writeFloat = Stream.writef32
Stream.readDouble = Stream.readf64
Stream.writeDouble = Stream.writef64

Class.makeProperClass(Stream, '@CHL/BufferWrapper/Stream')

module.Stream = Stream

return module
