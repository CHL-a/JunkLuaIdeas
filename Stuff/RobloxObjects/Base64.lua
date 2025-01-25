local Objects = script.Parent
local BufferWrapper = require(Objects["@CHL/BufferWrapper"])
local Dash = require(Objects["@CHL/DashSingular"])

type bufferw = BufferWrapper.object
type stream = BufferWrapper.stream

local module = {}

band = bit32.band
rshift = bit32.rshift
lshift = bit32.lshift
availible = 0
alphabet = table.create(63, 0xFF)
compose = Dash.compose
from = {}
to = {}
map = Dash.map

module.to = to
module.from = from
module.alphabet = alphabet
module.padding = ('='):byte()

function add_to_alphabet(range: string)
	local l = range:byte(2)
	for i = range:byte(1), l do
		module.alphabet[availible] = i
		availible += 1
	end
end

function transform_from(n1: number, n2: number, offset: number)
	local index = lshift(band(n1, 2 ^ offset - 1), 6 - offset) + 
		rshift(n2, 2 + offset)
	return alphabet[index]
end

-- primary encoding function
function from.bufferw(input: bufferw, len: number?): bufferw
	local l = len or input:len()
	local in_stream = BufferWrapper.Stream.new(input)
	local padding_len = l % 3 * 2 % 3
	local quadsets = l // 3
	local result = BufferWrapper.from.size(quadsets * 4 + math.min(padding_len, 1) * 4)
	local out_stream = BufferWrapper.Stream.new(result)
	
	
	for _ = 1, quadsets do
		local bytes = in_stream:getBytes(3)
		
		for j = 1, 4 do
			out_stream:writeu8(
				transform_from(bytes[j - 1] or 0, bytes[j] or 0, j * 2 - 2)
			)
		end
	end
	
	if padding_len > 0 then
		local byte1 = in_stream:readu8()
		
		out_stream:writeu8(transform_from(0, byte1, 0))
		
		if padding_len == 2 then
			out_stream:writeBytes(
				transform_from(byte1, 0, 2),
				module.padding,
				module.padding
			)
		else
			local byte2 = in_stream:readu8()
			
			out_stream:writeBytes(
				transform_from(byte1, byte2, 2),
				transform_from(byte2, 0, 4),
				module.padding
			)
		end
	end
	
	return result
end

function transform_to(n1: number, n2: number, offset: number)
	return band(lshift(n1, offset) + rshift(n2, 6 - offset), 0xFF)
end

function transform_to_code(i)return inverse_alphabet[i]end

-- primary decoding function
function to.bufferw(input: bufferw): bufferw
	local len = input:len()
	assert(len % 4 == 0, `Attempting to offer an invalid base64 string, got len: {len}`)
	local in_stream = BufferWrapper.Stream.new(input)
	local padding_len = 0
	
	if input:readu8(len - 1) == module.padding then
		padding_len += 1
		
		if input:readu8(len - 2) == module.padding then
			padding_len += 1
		end
	end
	
	local out_size = len // 4 * 3 - padding_len
	local result = BufferWrapper.from.size(out_size)
	local out_stream = BufferWrapper.Stream.new(result)
	
	local main_its = result:len() // 3
	
	for _ = 1, main_its do
		local codes = map(in_stream:getBytes(4),transform_to_code)
		
		for j = 1, 3 do
			out_stream:writeu8(transform_to(codes[j],codes[j+1], j * 2))
		end
	end
	
	if padding_len > 0 then
		local byte1, byte2 = unpack(map(in_stream:getBytes(2), transform_to_code))
		
		out_stream:writeu8(transform_to(byte1, byte2, 2))
		
		if padding_len == 1 then
			local byte3 = transform_to_code(in_stream:readu8())
			
			out_stream:writeu8(transform_to(byte2, byte3, 4))
		end
	end
	
	return result
end

add_to_alphabet'AZ'
add_to_alphabet'az'
add_to_alphabet'09'
module.alphabet[62] = ('+'):byte()
module.alphabet[63] = ('/'):byte()

inverse_alphabet = Dash.collect(alphabet, function(a0: number, a1: number)return a1, a0 end)
from.string = compose(BufferWrapper.from.string, from.bufferw) :: (string) -> bufferw;
to.string = compose(to.bufferw, BufferWrapper.toString) :: (bufferw)->string

return module
