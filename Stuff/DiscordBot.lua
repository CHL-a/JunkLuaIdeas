---@meta

--[[spec]]

---@class DiscordBot
---@field new fun(apiKey: string?): DiscordBot.bot
---@field toStruct fun(json: string): table
---@field user fun(s: string): DiscordBot.user

---@class DiscordBot.bot
---@field endPoint cURL.object
---@field webServer WebServer.object
---@field user DiscordBot.user
---@field onRequestCallback fun(c:TcpServer.client, req: cURL.ClientRequest, res: cURL.ServerResponse)
---@field setRequestCallback fun(f: fun(c:TcpServer.client, req: cURL.ClientRequest, res:cURL.ServerResponse)): DiscordBot.bot
---@field request fun(a: DiscordBot.request.argument): cURL.ServerResponse
---@field run fun()

---@class DiscordBot.request.argument
---@field suffix string
---@field type requestType
---@field data string?
---@field headers {[string]: string}?

---@alias snowflake string

---@class DiscordBot.user
---@field id snowflake specific id
---@field username string the user's username, not unique across the platform
---@field discriminator string the user's 4-digit discord-tag
---@field avatar string? the user's avatar hash
---@field bot boolean? whether the user belongs to an OAuth2 application
---@field system boolean? whether the user is an Official Discord System user (part of the urgent message system)
---@field mfa_enabled boolean whether the user has two factor enabled on their account
---@field banner string? the user's banner hash
---@field accent_color integer?	the user's banner color encoded as an integer representation of hexadecimal color code
---@field locale string? the user's chosen language option
---@field verified boolean? whether the email on this account has been verified
---@field email string? the user's email
---@field flags integer? the flags on a user's account
---@field premium_type integer? the type of Nitro subscription on a user's account
---@field public_flags integer? the public flags on a user's account

--[[code]]

---@type DiscordBot
local DiscordBot = {}

-- deps
local Static = require('Static')
local Environment = require('Environment')
local Enum = require('Enum')
local cURL = require('cURL')
local json = require('json')
local WebServer = require('WebServer')

---returns bot
---@param apiKey string? default is an Environment variable named "DiscordBotAPIKey"
---@param version integer? versioning of the api end point
---@return DiscordBot.bot
DiscordBot.new = function(apiKey, version)
	-- pre
	apiKey = assert(apiKey or Environment.get('DiscordBotToken'),
		'No api key, give argument or provide environment of index `DiscordBotToken` a valid token')
	version = version or 8

	-- main
	---@type DiscordBot.bot
	local object = {}

	local basicHeaders = {
		Authorization = 'Bot ' .. apiKey;
		['User-Agent'] = 'DiscordBot (TEST)';
		['X-RateLimit-Precision'] = 'millisecond'
	}
	
	object.endPoint = cURL.bind(('https://discord.com/api/v%d/'):format(version))

	--[[func]]

	---@param arg DiscordBot.request.argument
	---@return cURL.ServerResponse
	object.request = function(arg)
		return object.endPoint[tostring(arg.type):lower()](arg.suffix, arg.data, arg.headers)
	end

	--[[
	---@param arg DiscordBot.request.argument
	---@return fun(): cURL.ServerResponse
	local function request(arg)
        arg.type = arg.type or Enum.requestTypes.GET
		arg.headers = arg.headers or basicHeaders
		
        return function()
			return object.request(arg)
		end
    end
	--]]

	---Runs the discord bot, this function should be called as the last step
	object.run = function()
        -- pre
		assert(object.onRequestCallback, 'missing default callback')

		local response = object.request{
			suffix = 'users/@me';
			headers = basicHeaders;
			type = Enum.requestTypes.GET
		}
		
		assert(response.statusCode == 200, 'bad response: ' .. response.toString())
		
        -- main

		-- get user
        object.user = DiscordBot.user(response.body)
		assert(object.user.bot, 'user object for discord bot is not a bot')

        -- set up gateway,
        local cache = {}
		
		-- assume cache does not exist, must implement 
		local gatewayBotResponse = object.request {
            type = Enum.requestTypes.GET;
            headers = basicHeaders;
			suffix = '/gateway/bot'
        }
		
		assert(gatewayBotResponse.success, 'bad gateway bot response, see response: ' .. gatewayBotResponse.toString())

        local applicationInfoResponse = object.request {
            type = Enum.requestTypes.GET;
            headers = basicHeaders;
			suffix = '/oauth2/applications/@me'
		}

        assert(applicationInfoResponse.success,
            'bad application info response, see response: ' .. applicationInfoResponse.toString())
		
        local gatewayBotBody = json:decode(gatewayBotResponse.body)
        local applicationInfo = json:decode(applicationInfoResponse.body)
		
		cache[object.user.id] = {owner = applicationInfo.owner; shards = gatewayBotBody.shards}
        cache.url = gatewayBotBody.url

		-- end cache
		
		local currentPick = cache[object.user.id]

		print(Static.table.toString(currentPick))







		-- last step: set up webserver, set up discord to bot "connection", and launch server
        object.webServer = WebServer.new()
			.onInvalidRequest(object.onRequestCallback)
			.launch()
	end

	---sets callback
	---@param f fun(c: TcpServer.client, req: cURL.ClientRequest, res: cURL.ServerResponse)
	---@return DiscordBot.bot
    object.setRequestCallback = function(f)
		object.onRequestCallback = f

		return object
	end

	return object
end

---transforms a json object to a lua dictionary
---@param s string
---@return table
DiscordBot.toStruct = function(s)local result = json:decode(s)return result end

local snowflakeHashmap = {}

---@generic A
---@param func fun(t: A): A
function getObjectConstructor(func)
	return function(s)
		local result = DiscordBot.toStruct(s)

		if result.id and snowflakeHashmap[result.id] then
			result = snowflakeHashmap[result.id]
		else
			result = func(DiscordBot.toStruct(s))

			if result.id then
				snowflakeHashmap[result.id] = result
			end
		end
		
		return result
	end
end

DiscordBot.user = getObjectConstructor(function(t)
	---@cast t DiscordBot.user
	
	return t
end)

-- dead stuff that someone might use, idk 

	--[[
-- -@field handlePing fun(req: cURL.ClientRequest, res: cURL.ServerResponse): boolean
-- -@field verifyEd25519 fun(req: cURL.ClientRequest): boolean

local ed25519 = require('ed25519')


	---handles discord interaction "ping"
	---@deprecated
	---@param req cURL.ClientRequest
	---@param res cURL.ServerResponse
	---@return boolean
	object.handlePing = function (req, res)
		local result = false

		if req.headers['User-Agent'] == interactionUA then
			local body = json.decode(req.body)
			
			if body.type == 1 then
		   		-- print(Static.table.toString(json.decode(req.body)))
				local edVerified ;-- = object.verifyEd25519(req)
				
				res.statusCode = edVerified and 200 or 401
				res.statusMessage = edVerified and 'OK' or 'invalid request signature'
				res.body = edVerified and '{"type":1}' or 'Bad Signature'
				
				if edVerified then
					res.headers['Content-Type'] = Enum.mimeTypes.json
				end

				result = true
			end
			
		end
		return result
	end

	---verifies interaction, deprecated for being too slow
	---@deprecated
	---@param req cURL.ClientRequest
	---@return boolean
	object.verifyEd25519 = function (req)
		local result = false
		local edSig = req.headers['X-Signature-Ed25519']
		---@cast edSig string
		local timeStamp = req.headers['X-Signature-Timestamp']
		local body = req.body

		if edSig and timeStamp and body then
			print('|||got body')
			print(timeStamp .. body)
			print('||endbody')
			print('got sig: ', edSig)
			print('got apikey: ', apiKey)

			result = ed25519.verify(
					timeStamp .. body,
					ed25519.hexTo256(edSig),
					ed25519.hexTo256(apiKey)
			)
				print('ed verified: ', result)
		end

		return result
	end

	--]]


return DiscordBot