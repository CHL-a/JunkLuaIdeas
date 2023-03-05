-- SPEC
export type object = {
	attachment0: Attachment;
	attachment1: Attachment;
	alignPosition: AlignPosition;
	alignOrientation: AlignOrientation;
	
	setAttachment0: (self: object, a0: Attachment) -> nil;
	setAttachment1: (self: object, a1: Attachment) -> nil;
	
	togglePositioning: (self: object, isEnabled: boolean) -> nil;
	toggleOrientation: (self: object, isEnabled: boolean) -> nil;
	toggleEnabled: (self: object, isEnabled: boolean) -> nil;
}

-- CLASS
local AttachmentMagnet = {}
AttachmentMagnet.__index = AttachmentMagnet

AttachmentMagnet.new = function(a0: Attachment, a1: Attachment)
	local result = setmetatable({}, AttachmentMagnet)
	local result: object = result;
	
	result.alignPosition = Instance.new('AlignPosition', a0)
	result.alignOrientation = Instance.new('AlignOrientation', a0)
	
	result:setAttachment0(a0)
	result:setAttachment1(a1)
	
	return result
end

AttachmentMagnet.setAttachment0 = function(self:object, a0: Attachment)
	self.alignPosition.Attachment0 = a0;
	self.alignOrientation.Attachment0 = a0
	self.attachment0 = a0
end

AttachmentMagnet.setAttachment1 = function(self:object, a1: Attachment)
	self.alignPosition.Attachment1 = a1;
	self.alignOrientation.Attachment1 = a1
	self.attachment1 = a1
end

AttachmentMagnet.togglePositioning = function(self: object, isEnabled: boolean)
	self.alignPosition.Enabled = isEnabled;
end

AttachmentMagnet.toggleOrientation = function(self: object, isEnabled: boolean)
	self.alignOrientation.Enabled = isEnabled;
end

AttachmentMagnet.toggleEnabled = function(self: object, isEnabled: boolean)
	self:togglePositioning(isEnabled)
	self:toggleOrientation(isEnabled)
end

return AttachmentMagnet
