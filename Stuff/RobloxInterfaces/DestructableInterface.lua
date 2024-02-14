type __object = {
	isDestroyed: boolean;
	destroy: (self: __object) -> nil;
	Destroy: (self: __object) -> nil;
	assertDestruction: (self: __object) -> nil;
}
export type object = __object

local module = {}

module.destroy = function(self: __object)self.isDestroyed = true;end
module.Destroy = module.destroy
module.assertDestruction = function(self: __object)
	assert(
		not self.isDestroyed, 
		'Attempting to destroy a destroyed object.'
	)
end

return module
