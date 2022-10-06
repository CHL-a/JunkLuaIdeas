---@meta

---@class ByteCollection
---@field new fun(...: integer): ByteCollection.object

---@class ByteCollection.object
---@field bytes {[integer]: integer}
---@field bitwiseFixedLength integer
---@field check fun(boolean?): {byte:number,msg:string}?
---@field normalize fun(): ByteCollection.object
---@field toString fun(arg: 'hex'?): string
---@field toHexString fun(): string
---@field add fun(number): ByteCollection.object
---@field mult fun(number): ByteCollection.object
---@field idiv fun(number): ByteCollection.object
---@field logicShift fun(number): ByteCollection.object
---@field bitwiseNot fun(...:number): ByteCollection.object
---@field bitwiseAnd fun(...:number): ByteCollection.object
---@field bitwiseOr fun(...:number): ByteCollection.object
---@field bitwiseXor fun(...:number): ByteCollection.object

---@type ByteCollection
local ByteCollection = {}
local Static = require('Static')
local StringRadix = require('StringRadix')

ByteCollection.new = function(...)
	-- pre
	for i = 1, select('#', ...) do
		local v = select(i,...)
		assert(v % 1 == 0, 'non int')
		assert(v >= 0, 'got negative number')
		assert(v <= 255, 'got number bigger or equal to 256')
	end
	
	-- main
	---@type ByteCollection.object
	local object
	
	local function bitWiseOperation(func)
		return function(...)
			local bytes = object.bytes
			local args = {...}
			local a = #args
			
			-- inflate to fixed length
			while #bytes < object.bitwiseFixedLength do
				table.insert(bytes, 1, 0)
			end
			
			-- per byte
			for i = #bytes, 1, -1 do
				local arg = args[a] or 0
				assert(arg % 1 == 0, 'non integer: ' .. arg)
				assert(arg > -1, 'non negative number expected: ' .. arg)
				
				local argModded = arg % 256
				local byte = bytes[i]
				local newByte = 0
				
				-- run arg byte to byte
				for i = 0, 7 do
					local aBit = Static.math.getDigit(argModded, 2, i)
					local bBit = Static.math.getDigit(byte, 2, i)
					
					newByte = newByte + func(aBit, bBit) * 2 ^ i
				end
				
				bytes[i] = newByte
				
				-- incase of bigger than expected arguments
				if arg > 255 then
					args[a] = math.floor(arg / 256)
				elseif a > 1 then
					a = a - 1
				end
			end
			
			return object.normalize()
		end
	end
	
	object = {
		-- states
		bytes = {...};
		bitwiseFixedLength = 32;
		
		-- methods
		check = function(isPack)
			local resultA, resultB
			local result
			
			for i, v in next, object.bytes do
				resultB = 
					v % 1 ~= 0
						and 'got non int'
					or v < 0
						and 'got negative number'
					or v > 255
						and 'got number bigger or equal to 256'
					or ''
				
				if resultB == '' then
					resultB = nil
				else
					resultA = i
					break
				end
			end
			
			if resultA then
				result = not isPack and true or {
					byte = resultA;
					msg = resultB
				}
			end
			
			return result
		end,

		normalize = function()
			local bytes = object.bytes
			local i = #bytes
			local carry
			while i > 0 do
				-- manage with carry
				if carry then
					assert(carry % 1 == 0, 'non int found upon carry:' .. carry)
					
					bytes[i] = bytes[i] + carry
					carry = nil
				end
				
				local v = bytes[i]
				
				-- manage digits
				if v > 255 then -- add
					bytes[i] = v % 256
					carry = math.floor(v / 256)
				elseif v < 0 then -- sub
					if not bytes[i-1] then
						error(
							'byte collection is unsigned: ' 
							.. Static.table.toString(bytes)
						)
					end
					local a = bytes[i] % 256
					bytes[i] = a
					carry = -(a - v) / 256
				elseif i == 1 and #bytes ~= 1 and v == 0 then
					table.remove(bytes, 1)
					i = i + 1
				end
				
				-- post
				i = i - 1
			end
			
			if carry then
				table.insert(bytes, 1, carry)
			end
			if #bytes == 0 then
				table.insert(bytes, 0)
			end
			
			
			
			
			return object
		end,
		
		toString = function(isHex)
			local result = ''
			
			for _, v in next, object.bytes do
				local suffix = string.char(v)
				
				if isHex then
					suffix = StringRadix.hexdecimal.getDigitSequence(v)
					
					if #suffix == 1 then
						suffix = '0' .. suffix
					end
				end
				
				result = result .. suffix
			end
			
			return result
		end,
		toHexString = function()return object.toString('hex')end,
		
		add = function(n)
			local bytes = object.bytes
			
			bytes[#bytes] = bytes[#bytes] + n
			
			return object.normalize()
		end,
		
		mult = function(n)
			-- pre
			assert(n % 1 == 0, 'bad arg, non int: ' .. n)
			assert(n > -1, 'n should be non negative: ' .. n)
			
			-- main	
			local bytes = object.bytes
			
			for i = 1, #bytes do
				bytes[i] = bytes[i] * n
			end
			
			return object.normalize()
		end,
		
		idiv = function(n)
			-- pre
			assert(n % 1 == 0, 'bad arg, non int: ' .. n)
			assert(n > -1, 'n should be non negative: ' .. n)
			
			-- main
			local carry = 0
			
			for a = 1, #object.bytes do
				local v = (object.bytes[a] + carry * 256)
				object.bytes[a] = math.floor(v / n)
				carry = v % n
			end
			
			return object.normalize()
		end,
		
		logicShift = function(n)
			-- pre
			assert(n % 1 == 0, 'bad arg, non int: ' .. n)
			assert(n ~= -1, 'n should be non-zero ' .. n)
			
			-- main
			if n > 0 then -- right shift (int dividing by 2)
				for i = 1, n do
					object.idiv(2)
				end
			else -- left shift (mult by 2)
				for i = 1, -n do
					object.mult(2)
				end
			end
			
			return object
		end,
		
		bitwiseNot = bitWiseOperation(function(_, b)return (b + 1) % 2 end);
		bitwiseAnd = bitWiseOperation(function(a, b)return a * b end);
		bitwiseOr = bitWiseOperation(function(a, b)return math.min(1, a + b) end);
		bitwiseXor = bitWiseOperation(function(a, b)return (a + b) % 2 end);
	}
	
	local pack = object.check(true)
	
	if pack then
		error(
			('Failed precondition: \n\tbyte=%s\n\tmsg=%s'):format(
				pack.byte,
				pack.msg
			)
		)
	end
	
	return object.normalize()
end

return ByteCollection