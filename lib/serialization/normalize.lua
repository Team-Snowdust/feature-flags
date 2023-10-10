--[=[
	Options to initialize the serialization process with.

	.store? DataStore -- The name of the DataStore to use for serialization
	.synchronizationInterval? number -- The interval in seconds to synchronize flags

	@interface InitializationOptions
	@within FeatureFlags
]=]
export type InitializationOptions = {
	store: string?,
	synchronizationInterval: number?,
}

--[=[
	Normalized options to initialize the serialization process with.

	.store DataStore -- The name of the DataStore to use for serialization
	.synchronizationInterval number -- The interval in seconds to synchronize flags

	@interface NormalizedOptions
	@within Serialization
]=]
export type NormalizedOptions = {
	store: string,
	synchronizationInterval: number,
}

--[=[
	Normalizes the options to initialize the serialization process with.

	@within Serialization
]=]
local function normalizeOptions(options: InitializationOptions?): NormalizedOptions
	return {
		store = if options and options.store then options.store else "FeatureFlags",
		synchronizationInterval = if options and options.synchronizationInterval
			then options.synchronizationInterval
			else 60,
	}
end

return normalizeOptions
