export type object = {
	isDestroyed: boolean;
	destroy: (self: object) -> ();
	Destroy: (self: object) -> ();
	assertDestruction: (self: object) -> ();
}

module = {}

function module.destroy(self: object)self.isDestroyed = true;end

function module.assertDestruction(self: object)
	assert(
		not self.isDestroyed, 
		'Attempting to destroy a destroyed object.'
	)
end

module.Destroy = module.destroy

return module
