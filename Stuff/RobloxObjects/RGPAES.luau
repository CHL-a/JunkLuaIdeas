--[[
	A module assisting on AES by RobloxGamerPro200007
	
	Original: https://create.roblox.com/store/asset/11195079384/Advanced-Encryption-Standard-AES
--]]

local module = {}

buffer_len = buffer.len
buffer_readu8 = buffer.readu8
buffer_writeu8 = buffer.writeu8

function module.get_module()return require('./@RobloxGamerPro200007>AES')end

--[[
	The methodology of this function is to normalize the key to 32 bytes, anything above 32 bytes will be truncated and anything under is filled with 0x00
]]
function module.normalize_key(key: string | buffer, explicit_truncate: boolean?): buffer
	local is_buffer = typeof(key) == "buffer"
	local len = if is_buffer then buffer_len(key) else #(key :: string)
	local result = buffer.create(32)
	local key_len = math.min(32, len)
	
	if len > 32 and not explicit_truncate then
		warn("Key is longer than 32 bytes, it will be truncated, redo key or explicitly truncate by setting explicit_truncate to true")
	end
	
	for i = 1, key_len do
		local byte = if is_buffer then buffer_readu8(key, i - 1) else string.byte((key :: string), i)
		
		buffer_writeu8(result, i - 1, byte)
	end
	
	return result
end

--[[
	proxy function for native .new
]]
function module.new(key: buffer | string, mode, padding)
	local aes_original = module.get_module()
	return aes_original
		.new(module.normalize_key(key), mode or aes_original.modes.CBC, padding or aes_original.pads.Iso10126)
end

function module.modes()return module.get_module().modes end
function module.pads()return module.get_module().pads end

return module
