-- SPEC
export type object = {
	player: Player;
	folder: Folder;
	
	getHeldCharacterTool: (self: object) -> Tool?;
	sendToArchive: (self: object, Tool) -> nil;
	sendAllToArchive: (self: object) -> nil;
	retrieveFromArchive: (self: object, Tool) -> nil;
	retrieveAllFromArchive: (self: object) -> nil
}

-- CLASS
local ToolArchiver = {}
ToolArchiver.__index = ToolArchiver;

ToolArchiver.new = function(player: Player): object
	local result = setmetatable({}, ToolArchiver)
	local states : object = result
	states.player = player;
	states.folder = Instance.new('Folder', player)
	states.folder.Name = 'ToolArchive'
	return result
end

ToolArchiver.getHeldCharacterTool = function(self: object)
	-- pre
	local p = self.player;
	if not (p and p:IsDescendantOf(game)) then return end
	
	local c = p.Character
	if not (c and c:IsDescendantOf(game)) then return end
	
	-- main
	return c:FindFirstChildWhichIsA('Tool')
end

ToolArchiver.sendToArchive = function(self: object, tool: Tool)tool.Parent=self.folder;end

ToolArchiver.sendAllToArchive = function(self: object)
	while self:getHeldCharacterTool() do
		self:sendToArchive(assert(self:getHeldCharacterTool()))
	end
	
	local backpack = self.player:FindFirstChildWhichIsA('Backpack')
	if not backpack then return end
	
	for _, v in next,backpack:GetChildren() do self:sendToArchive(v)end
end

ToolArchiver.retrieveFromArchive = function(self: object, tool: Tool)
	local backpack = self.player and self.player:FindFirstChildWhichIsA('Backpack')
	if not backpack then return end
	
	tool.Parent = backpack
end

ToolArchiver.retrieveAllFromArchive = function(self: object)
	for _, v in next, self.folder:GetChildren() do
		self:retrieveFromArchive(v)
	end
end


return ToolArchiver