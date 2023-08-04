local Package = script.Parent
local Flags = require(Package.Flags)
local Signal = require(script.Parent.Signal)
local isActive = require(Package.isActive)

--[=[
	Represents an individual flag.

	This provides convenience access to other library functions with this flag
	already provided. See [FeatureFlags] for more information about each function.

	@class Flag
]=]
export type Flag = {
	name: string,
	create: (config: Flags.FlagConfig, retired: boolean?) -> (),
	exists: () -> boolean,
	read: () -> Flags.FlagData,
	update: (config: Flags.FlagConfig) -> (),
	retire: (retired: boolean?) -> (),
	destroy: () -> (),
	isActive: (context: isActive.ActivationContext?, config: isActive.ActivationConfig?) -> boolean,
	onChange: (callback: (record: Flags.ChangeRecord) -> ()) -> Signal.Connection,
}

--[=[
	The name of this flag.

	@prop name string
	@within Flag
	@readonly
]=]

--[=[
	Creates a new flag with the provided configuration.

	:::caution
	Receiving a Flag object generally indicates that a flag already exists. The
	`create` function should only be used to create flags that don't already
	exist.
	:::

	See: [create](FeatureFlags#create)

	@param config FlagConfig
	@param retired? boolean -- Whether this flag is retied

	@error "Flag '%s' already exists." -- Thrown when a flag with this name already exists.

	@function create
	@within Flag
]=]

--[=[
	Checks if this flag currently exists.

	See: [exists](FeatureFlags#exists)

	@return boolean

	@function exists
	@within Flag
]=]

--[=[
	Reads the data of this flag.

	See: [read](FeatureFlags#read)

	@return FlagData

	@function read
	@within Flag
]=]

--[=[
	Updates the configuration of this flag.

	See: [update](FeatureFlags#update)

	@param config FlagConfig

	@function update
	@within Flag
]=]

--[=[
	Sets the retired status of this flag.

	See: [retire](FeatureFlags#retire)

	@param retired? boolean

	@function retire
	@within Flag
]=]

--[=[
	Removes this flag entirely.

	See: [destroy](FeatureFlags#destroy)

	@function destroy
	@within Flag
]=]

--[=[
	Checks if a feature flag is active based on provided context and
	configuration.

	See: [isActive](FeatureFlags#isActive)

	@param context? ActivationContext
	@param config? ActivationConfig

	@return boolean

	@function isActive
	@within Flag
]=]

--[=[
	Subscribe to the changed event for this flag.

	This callback is only invoked when this flag is changed.

	See: [Changed](FeatureFlags#Changed)

	@param callback (record: ChangeRecord) -> ()

	@return Connection

	@function onChange
	@within Flag
]=]

--[=[
	Creates a new flag object.

	@within Flag
	@ignore
]=]
local function createFlag(name: string): Flag
	return table.freeze({
		name = name,

		create = function(config: Flags.FlagConfig, retired: boolean?)
			Flags.create(name, config, retired)
		end,

		exists = function(): boolean
			return Flags.exists(name)
		end,

		read = function(): Flags.FlagData
			return Flags.read(name)
		end,

		update = function(config: Flags.FlagConfig)
			Flags.update(name, config)
		end,

		retire = function(retired: boolean?)
			Flags.retire(name, retired)
		end,

		destroy = function()
			Flags.destroy(name)
		end,

		isActive = function(
			context: isActive.ActivationContext?,
			config: isActive.ActivationConfig?
		): boolean
			return isActive(name, context, config)
		end,

		onChange = function(callback: (record: Flags.ChangeRecord) -> ()): Signal.Connection
			return Flags.Changed:Connect(function(changedName: string, record: Flags.ChangeRecord)
				if changedName == name then
					callback(record)
				end
			end)
		end,
	})
end

return createFlag
