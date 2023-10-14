local DataStoreService = game:GetService("DataStoreService")
local Package = script.Parent
local PromiseTypes = require(Package.types.Promise)
local StoreTypes = require(script.types.store)

local Flags = require(Package.Flags)
local Promise = require(Package.Parent.Promise) :: PromiseTypes.PromiseStatic
local Signal = require(Package.Parent.Signal)

local fetchDirectory = require(script.fetchDirectory)
local fetchFlags = require(script.fetchFlags)
local normalize = require(script.normalize)
local sendFlags = require(script.sendFlags)

export type Connection = Signal.Connection
export type InitializationOptions = normalize.InitializationOptions

--[=[
	Internal serialization module features for feature flags.

	@class Serialization
	@ignore
]=]

--[=[
	Merges two RepositoryUpdates tables together, preferring the greater version.

	@within Serialization
]=]
local function mergeUpdates(
	left: StoreTypes.RepositoryUpdates,
	right: StoreTypes.RepositoryUpdates
): StoreTypes.RepositoryUpdates
	local updates = table.clone(left)

	for repositoryName, flags in right do
		local repository = updates[repositoryName]
		if not repository then
			updates[repositoryName] = flags
		else
			for flagName, flag in flags do
				local version = repository[flagName]
				repository[flagName] = if flag > version then flag else version
			end
		end
	end

	return updates
end

--[=[
	Removes a set of flags.

	@within Serialization
]=]
local function removeFlags(removals: { [string]: true })
	for flag in removals do
		Flags.destroy(flag)
	end
end

--[=[
	Starts the serialization process.

	Provides a cancellable promise that will never resolve. This continually polls
	for changes to the flags in data stores and synchronizes them with the local
	flags. Synchronization happens in specified intervals to avoid rate limits.

	Directory synchronization is done synchronously, while flag synchronization
	is done asynchronously.

	@within Serialization
]=]
local function startSerialization(
	flagChanges: StoreTypes.FlagChanges,
	options: InitializationOptions?
): PromiseTypes.Promise<never>
	return Promise.new(function(_, _, onCancel: (() -> ()) -> ())
		local serialize: PromiseTypes.Promise<nil>?
		local deserialize: PromiseTypes.Promise<nil>?
		local initialized = true

		onCancel(function()
			initialized = false

			if serialize then
				serialize:cancel()
				serialize = nil
			end
			if deserialize then
				deserialize:cancel()
				deserialize = nil
			end
		end)

		local options = normalize(options)
		local store: StoreTypes.SerializationStore = {
			index = DataStoreService:GetDataStore(options.store),
			managed = DataStoreService:GetDataStore(options.store, "managed"),
			user = DataStoreService:GetDataStore(options.store, "user"),

			directory = {},

			managedUpdates = {},
			userUpdates = {},
		}

		while initialized do
			-- Synchronously deserialize the directory
			local updates
			store.directory, updates = fetchDirectory(store.index, store.directory)

			store.managedUpdates = mergeUpdates(store.managedUpdates, updates.managed)
			store.userUpdates = mergeUpdates(store.userUpdates, updates.user)
			removeFlags(updates.removed)

			-- Begin asynchronous serialization and deserialization
			serialize = sendFlags(store, flagChanges)
			deserialize = fetchFlags(store)

			-- Wait for the next synchronization interval
			task.wait(options.synchronizationInterval)

			-- Cancel any currently executing serialization tasks
			if serialize then
				serialize:cancel()
				serialize = nil
			end
			if deserialize then
				deserialize:cancel()
				deserialize = nil
			end
		end
	end)
end

--[=[
	Initializes the serialization process.

	Begins synchronizing flags with the data store. This will listen for local
	changes to flags that are marked for serialization and update the data store
	accordingly. Local changes are listened for continuously, but only sent to
	the data store in specified intervals to help avoid rate limits.

	:::info
	This should be started as soon as possible in a game's lifecycle to ensure
	that flags are synchronized as soon as possible. Any features that depend on
	serialized flags will be unavailable until this is started and synchronized.
	:::

	```lua
	init({
		store = "MyFeatureFlagStore",
		synchronizationInterval = 300, -- 5 minutes
	})
	```

	The initial synchronization happens immediately as this is called. This
	ensures that flags are available as soon as possible. Later synchronizations
	will happen in the specified interval.

	Flag changes can easily be marked for serialization by updating them while
	passing the `serialize` option of [UpdateOptions]. This will mark the flag as
	needing serialization and will be synchronized with the data store during the
	next synchronization interval.

	```lua
	-- This flag will not be serialized
	update("localFlag", {
		-- Desired flag changes
	})

	-- Mark this flag for serialization
	update("serializedFlag", {
		-- Desired flag changes
	}, {
		serialize = true,
	})
	```

	This is a convenience function that takes care of gathering flag changes and
	synchronizing them with a data store. If you need more control over the
	serialization process, you can create your own bespoke serialization process
	instead using the [Changed](#Changed) event and the `serialize` option of
	[UpdateOptions].

	@param options? InitializationOptions -- Options to initialize the serialization process

	@return Connection -- A connection that can be used to disconnect the serialization process

	@function init
	@within FeatureFlags
]=]
local function initialize(options: InitializationOptions?): Connection
	local flagChanges: StoreTypes.FlagChanges = {}

	local flagsConnection = Flags.Changed:Connect(
		function(name: string, record: Flags.ChangeRecord, options: Flags.UpdateOptions)
			if not options.serialize then
				return
			end

			flagChanges[name] = { change = record.new }
		end
	)

	local serialization = startSerialization(flagChanges, options)

	return {
		disconnect = function()
			flagsConnection.disconnect()
			serialization:cancel()
		end,

		isConnected = function()
			return flagsConnection.isConnected()
		end,
	}
end

return initialize
