type __object = {
	isDestroyed: boolean;
	destroy: (self: __object) -> nil;
	assertDestruction: (self: __object) -> nil;
}

local module = {}

module.destroy = function(self: __object)self.isDestroyed = true;end
module.assertDestruction = function(self: __object)
	assert(
		not self.isDestroyed, 
		'Attempting to destroy a destroyed object.'
	)
end
return module
