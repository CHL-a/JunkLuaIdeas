--[[
	Does the same thing as encoding service, except it's not an explicit instance. 
	Particularly, it has the ability to encode/decode but it also has instance methods.
	This service provides a reference to EncodingService but also has more direct 
	functions towards their purpose for auto complete
]]

module = {}

module.services = {
	encode = game:GetService('EncodingService');
	http = game:GetService('HttpService');
}

--#####################################################################################
--#####################################################################################
--#####################################################################################

function service_call_1(service_index: string, method_call: string)
	return function(...)
		local service = module.services[service_index]
		assert(service)
		
		return service[method_call](service, ...)
	end
end

function service_call_2<A>(service_index: string, method_call: string, enum_type: A)
	return function(buff, ...)
		local service = module.services[service_index]
		assert(service)

		return service[method_call](service, buff, enum_type, ...)
	end
end

--#####################################################################################
--#####################################################################################
--#####################################################################################
-- JSON

local Map = require('./@CHL>Map')

type dict<T> = Map.dictionary<T>

module.encoding = {}
module.encoding.json = {}
module.encoding.json.encode = service_call_1('http', 'JSONEncode') :: (dict<any>) -> string
module.encoding.json.decode = service_call_1('http', 'JSONDecode') :: (string) -> dict<any>

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- Base64
--[[
	This part speciifically uses a buffer to buffer conversion to encode and decode, 
	instead of iterators and consumers. If you're interested, then see @CHL>Base64 for 
	more information.
]]

module.encoding.base64 = {}
module.encoding.base64.encode = service_call_1('encode', 'Base64Encode') :: (buffer) -> buffer
module.encoding.base64.decode = service_call_1('encode', 'Base64Decode') :: (buffer) -> buffer

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- zstd
module.compression = {}
module.compression.zstd = {}
module.compression.zstd.compress = service_call_2('encode', 'CompressBuffer', Enum.CompressionAlgorithm.Zstd) :: (buffer, compression_level: number) -> buffer
module.compression.zstd.decompress = service_call_2('encode', 'DecompressBuffer', Enum.CompressionAlgorithm.Zstd) :: (buffer) -> buffer
module.compression.zstd.get_decompressed_size = service_call_2('encode', 'GetBufferDecompressedSize', Enum.CompressionAlgorithm.Zstd) :: (buffer) -> number

--#####################################################################################
--#####################################################################################
--#####################################################################################

-- all hashing functions
module.hash = {}
module.hash.blake2b = service_call_2('encode', 'ComputeBufferHash', Enum.HashAlgorithm.Blake2b) :: (buffer) -> buffer
module.hash.blake3 = service_call_2('encode', 'ComputeBufferHash', Enum.HashAlgorithm.Blake3) :: (buffer) -> buffer
module.hash.md5 = service_call_2('encode', 'ComputeBufferHash', Enum.HashAlgorithm.Md5) :: (buffer) -> buffer
module.hash.sha1 = service_call_2('encode', 'ComputeBufferHash', Enum.HashAlgorithm.Sha1) :: (buffer) -> buffer
module.hash.sha256 = service_call_2('encode', 'ComputeBufferHash', Enum.HashAlgorithm.Sha256) :: (buffer) -> buffer

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
