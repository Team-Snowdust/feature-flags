local Package = script.Parent
local LinkedList = require(Package.LinkedList)

export type Connection = {
	disconnect: () -> (),
	isConnected: () -> boolean,
}

export type Callback = (...unknown) -> ()

type Listener = {
	callback: Callback,
	connection: Connection,
}

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self.Event = setmetatable({}, {
		__index = {
			Connect = function(_, callback)
				return self:Connect(callback)
			end,
		},
	})
	self.listeners = LinkedList.new()

	return self
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
