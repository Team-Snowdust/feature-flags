local Package = script.Parent
local Flags = require(Package.Flags)
local Promise = require(Package.Parent.Promise)
local PromiseTypes = require(Package.types.Promise)
local Signal = require(script.Parent.Signal)
local createFlag = require(Package.createFlag)

--[=[
	Gets a flag asynchronously.

	```lua
	get("newActivity"):andThen(function(flag: Flag)
		-- The flag is available to use.
		if flag.isActive() then
			-- The flag is active.
		end
	end)
	```

	@param name -- The name of the flag

	@return Promise<Flag> -- A Promise of the Flag requested

	@within FeatureFlags
]=]
local function get(name: string): PromiseTypes.Promise<createFlag.Flag>
	return Promise.new(function(resolve: (createFlag.Flag) -> (), _, onCancel: (() -> ()) -> ())
		if Flags.exists(name) then
			resolve(createFlag(name))
			return
		end

		local connection: Signal.Connection
		connection = Flags.Changed:Connect(function(changedName: string, record: Flags.ChangeRecord)
			if changedName ~= name then
				return
			end
			if not record.new then
				return
			end

			connection.disconnect()
			resolve(createFlag(name))
		end)

		onCancel(function()
			connection.disconnect()
		end)
	end)
end

return get
