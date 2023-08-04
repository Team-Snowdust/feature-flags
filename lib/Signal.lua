local Package = script.Parent
local LinkedList = require(Package.LinkedList)

--[=[
	Disconnects this connection.

	@function disconnect
	@within Connection
]=]

--[=[
	Checks if this function is currently connected.

	@function isConnected
	@within Connection
	@return boolean
]=]

--[=[
	A connection created by an [Event].

	@class Connection
]=]
export type Connection = {
	disconnect: () -> (),
	isConnected: () -> boolean,
}

--[=[
	A function called when an Event fires.

	@type Callback (...unknown) -> ()
	@within Event
]=]
export type Callback = (...unknown) -> ()

type Listener = {
	callback: Callback,
	connection: Connection,
}

--[=[
	A Signal for firing events.

	@class Signal
	@ignore
]=]
local Signal = {}
Signal.__index = Signal

--[=[
	Creates a new Signal.
]=]
function Signal.new()
	local signal = setmetatable({}, Signal)

	--[=[
		An Event that you can subscribe to.

		This is effectively the subscription end of a Signal.

		@class Event
	]=]
	local Event = {}
	Event.__index = Event

	--[=[
		Connect a [Callback] to this Event.

		The Callback will be called every time this Event fires. It can be
		disconnected through the returned [Connection].

		@within Event
	]=]
	function Event:Connect(callback: Callback): Connection
		return signal:Connect(callback)
	end

	signal.Event = setmetatable({}, Event)
	signal.listeners = LinkedList.new()

	return signal
end

--[=[
	Connect a [Callback] to this Signal.

	The Callback will be called every time this Signal fires. It can be
	disconnected through the returned [Connection].
]=]
function Signal:Connect(callback: Callback): Connection
	local entry: LinkedList.Entry<unknown>?

	local listener: Listener = {
		callback = callback,
		connection = {
			disconnect = function()
				if not entry then
					return
				end

				entry.remove()
				entry = nil
			end,

			isConnected = function(): boolean
				return entry ~= nil
			end,
		},
	}

	entry = self.listeners:Push(listener)
	return listener.connection
end

--[=[
	Fires this Signal.

	Any parameters can be provided that will be passed to any listening
	[Callback]s.
]=]
function Signal:Fire(...: unknown)
	for listener in self.listeners do
		task.spawn(listener.callback, ...)
	end
end

--[=[
	Disconnects every listener from this Signal.
]=]
function Signal:DisconnectAll()
	for listener in self.listeners do
		listener.connection.disconnect()
	end
end

return Signal
