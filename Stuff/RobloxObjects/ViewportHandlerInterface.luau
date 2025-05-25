export type viewporthandler_module = {
	new: (Frame) -> viewporthandler;
}

export type viewporthandler = {
	RenderObject: (self: viewporthandler, object: BasePart, fps: number?, Parent: Instance?) -> objecthandler;
	RenderHumanoid: (self: viewporthandler, character: Model, fps: number?, Parent: Instance?) -> humanoidhandler;
	Destroy: (self: viewporthandler) -> ();
	Refresh: (self: viewporthandler) -> ();
	Pause: (self: viewporthandler) -> ();
	Resume: (self: viewporthandler) -> ();
	Hide: (self: viewporthandler) -> ();
	Show: (self: viewporthandler) -> ();
}

export type objecthandler = {
	Destroy: (self: objecthandler) -> ();
	SetFPS: (self: objecthandler, new_fps: number) -> ();
	Pause: (self: objecthandler) -> ();
	Resume: (self: objecthandler) -> ();
	Refresh: (self: objecthandler) -> ();
	Hide: (self: objecthandler) -> ();
	Show: (self: objecthandler) -> ();
}

export type humanoidhandler = {
	ObjHandlers: {objecthandler};
	Destroy: (self: humanoidhandler) -> ()
}

module = {}

disguise = require('./LuaUTypes').disguise

function module.get(): viewporthandler_module
	return require('./@boatbomber>ViewportHandler')
end

return module
