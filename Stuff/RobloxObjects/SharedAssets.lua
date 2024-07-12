local Objects = script.Parent
local Object = require(Objects.Object)
local InstanceUtils = require(Objects["@CHL/InstanceUtils"])

export type object = {
	folder: Folder;
	
	findAsset: <A>(self :object, ...string) -> A?;
	getAsset: <A>(self: object, ...string) -> A;
	permitShare: <A>(self: object, A, ...string) -> ();
	waitForAsset: <A>(self: object, ...string) -> A;
} & Object.object_inheritance

local module = {}

isClient = game:GetService('RunService'):IsClient()
disguise = require(Objects.LuaUTypes).disguise

function module.new(f: Folder): object
	local self: object = Object.from.class(module)
	
	self.folder = f
	
	return self
end

function module.findAsset(self: object, ...:string)
	return (InstanceUtils.findFirstDescendant(self.folder, ...))
end

function module.getAsset(self: object, ...:string)
	return assert(
		self:findAsset(...), 
		`Cant find:| {table.concat({...}, '.')}| Of: {self.folder:GetFullName()}`
	)
end

function module.waitForAsset(self: object, ...:string)
	return InstanceUtils.waitForDescendant(self.folder, ...)
end

function module.permitShare<A>(self: object, now: A, ...)
	local parent = self:getAsset(...)
	disguise(now):Clone().Parent = parent
end

module.__index = module
module.className = '@CHL/SharedAssets'
return module
