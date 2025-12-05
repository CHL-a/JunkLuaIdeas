--[[
	Roblox username color algorithm, decomposed (edited)

	From: https://devforum.roblox.com/t/your-name-color-in-chat-%E2%80%94-history-and-how-it-works/2702247
]]

local module = {}

from_rgb = Color3.fromRGB

--[[
	Pallette from: https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/8/f/1/7/8f174803477cff6e411eca876f3ebca73e28a3bb.png
]]
module.palette = {
	legacy_2006 = {
		from_rgb(196, 40, 28),
		from_rgb(13, 105, 172),
		from_rgb(39, 70, 45),
		from_rgb(107, 50, 124),
		from_rgb(218, 133, 65),
		from_rgb(245, 205, 48),
		from_rgb(232, 186, 200),
		from_rgb(215, 197, 154)
	};
	legacy_2015 = {
		from_rgb(253, 41, 67),
		from_rgb(1, 132, 255),
		from_rgb(2, 184, 87),
		from_rgb(107, 50, 124),
		from_rgb(218, 133, 65),
		from_rgb(245, 205, 48),
		from_rgb(232, 186, 200),
		from_rgb(215, 197, 154)
	};
	textchatservice = {
		from_rgb(253, 41, 67),
		from_rgb(1, 132, 255),
		from_rgb(2, 184, 87),
		from_rgb(180, 128, 255),
		from_rgb(218, 133, 65),
		from_rgb(245, 205, 48),
		from_rgb(232, 186, 200),
		from_rgb(215, 197, 154)
	}
}

-- fetches index from string, typically, usernames
function module.get_index(s: string): number
	local result = 0
	local n = #s
	
	for i = 1, n do
		local byte = s:byte(i)
		local j = n - i + 1 -- reverse i
		
		if n % 2 == 1 then
			j -= 1
		end
		
		if j % 4 >= 2 then
			byte = -byte
		end
		
		result += byte
	end
	
	return result
end

function module.get_color(s: string, pallete: {Color3}?): Color3
	local pallete = pallete or module.palette.textchatservice
	return pallete[module.get_index(s) % #pallete + 1]
end

return module
