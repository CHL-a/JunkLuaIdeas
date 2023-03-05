---@alias Iterator<A> fun(): fun(): A?

---@class Discordia reserved class for holding other classes

---@class Discordia.Emitter Class type where callbacks are "emitted" or "recieved". These callbacks are called listeners and they can be subcribed
---@field emit fun(name: string, ...: any?): nil Emits the named event and a variable number of arguments to pass to the event callbacks.
---@field getListener fun(name: string): number Returns the number of callbacks registered to the named event.
---@field getListeners fun(name: string): Iterator<Discordia.Emitter.listener> Returns an iterator for all callbacks registered to the named event.
---@field on Discordia.Emitter.subscriber Subscribes a callback to be called every time the named event is emitted. Callbacks registered with this method will automatically be wrapped as a new coroutine when they are called. Returns the original callback for convenience.
---@field onSync Discordia.Emitter.subscriber Subscribes a callback to be called every time the named event is emitted. Callbacks registered with this method are not automatically wrapped as a coroutine. Returns the original callback for convenience.
---@field once Discordia.Emitter.subscriber Subscribes a callback to be called only the first time this event is emitted. Callbacks registered with this method will automatically be wrapped as a new coroutine when they are called. Returns the original callback for convenience.
---@field onceSync Discordia.Emitter.subscriber Subscribes a callback to be called only the first time this event is emitted. Callbacks registered with this method are not automatically wrapped as a coroutine. Returns the original callback for convenience.
---@field removeAllListeners fun(name?): nil Unregisters all callbacks for the emitter. If a name is passed, then only callbacks for that specific event are unregistered.
---@field removeListener fun(name: string, fn: Discordia.Emitter.listener): nil Unregisters all instances of the callback from the named event.
---@field waitFor fun(name: string, timeout: number, predicate): boolean, ... When called inside of a coroutine, this will yield the coroutine until the named event is emitted. If a timeout (in milliseconds) is provided, the function will return after the time expires, regardless of whether the event is emitted, and false will be returned; otherwise, true is returned. If a predicate is provided, events that do not pass the predicate will be ignored.

---@alias Discordia.Emitter.listener<A...> fun(...: A...)

---@alias Discordia.Emitter.subscriber fun(name: string, fn: Discordia.Emitter.listener): Discordia.Emitter.listener

---@generic A: any
---@class Discordia.Iterable<A> Abstract base class that defines the base methods and properties for a general purpose data structure with features that are better suited for an object-oriented environment. Note: All sub-classes should implement their own __init and iter methods and all stored objects should have a __hash method.
---@field count fun(fn: fun(A: A): boolean): integer If a predicate is provided, this returns the number of objects in the iterable that satisfy the predicate; otherwise, the total number of objects.
---@field find fun(fn: fun(A: A): boolean): A Returns the first object that satisfies a predicate. `A`
---@operator len: integer Length if collection
---@field findAll fun(f: fun(A: A): boolean): Iterator<A> Returns an iterator that returns all objects that satisfy a predicate.
---@field forEach fun(f: fun(A: A)) Iterates through all objects and calls a function fn that takes the objects as an argument.
---@field get fun(k): A Returns an individual object by key, where the key should match the result of calling __hash on the contained objects. Operates with up to O(n) complexity.





---@class Discordia.Client
---@field email string? The current user's owner's account's email address (user-accounts only).
-- -@field groupChannels






return nil