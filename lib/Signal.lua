local Package = script.Parent
local LinkedList = require(Package.LinkedList)

--[=[
	@class Connection
]=]
export type Connection = {
	disconnect: () -> (),
	isConnected: () -> boolean,
}

--[=[
	@within Event
]=]
export type Callback = (...unknown) -> ()

type Listener = {
	callback: Callback,
	connection: Connection,
}

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local signal = setmetatable({}, Signal)

	--[=[
		@class Event
	]=]
	local Event = {}
	Event.__index = Event

	--[=[
		@within Event
	]=]
	function Event:Connect(callback: Callback): Connection
		return signal:Connect(callback)
	end

	signal.Event = setmetatable({}, Event)
	signal.listeners = LinkedList.new()

	return signal
end

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

function Signal:Fire(...)
	for listener in self.listeners do
		task.spawn(listener.callback, ...)
	end
end

function Signal:DisconnectAll()
	for listener in self.listeners do
		listener.connection.disconnect()
	end
end

return Signal
