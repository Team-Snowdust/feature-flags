local Serialization = script.Parent
local Package = Serialization.Parent
local PromiseTypes = require(Package.types.Promise)
local StoreTypes = require(Serialization.types.store)
local serializeFlagsToDirectory = require(script.Parent.serializeFlagsToDirectory)

local Promise = require(Package.Parent.Promise) :: PromiseTypes.PromiseStatic
local serializeRepository = require(script.Parent.serializeRepository)

--[=[
	Sends the given flag changes to the data store provided.

	This send operation is synchronous, and will not return until the data store
	has been updated. This is because the data store is not thread-safe, and
	therefore cannot be updated asynchronously. This is the action by which the
	serialization process is synchronized with the data store and that we ensure
	that we have exclusive write access to these flags before we attempt to update
	them.

	This returns a set of changes to repositories that can be sent to the data
	store. These changes are the result of the flag changes that were sent to the
	directory, ensuring safe and consistent updates to the data store.

	@within Serialization
]=]
local function sendFlagsToDirectory(
	store: StoreTypes.SerializationStore,
	flagChanges: StoreTypes.FlagChanges
): (StoreTypes.RepositoryChanges, StoreTypes.RepositoryChanges)
	local managedChanges: StoreTypes.RepositoryChanges
	local userChanges: StoreTypes.RepositoryChanges

	store.index:UpdateAsync("flags", function(directory: StoreTypes.Directory): StoreTypes.Directory
		directory, managedChanges, userChanges =
			serializeFlagsToDirectory(store.directory, directory, flagChanges)

		return directory
	end)

	return managedChanges, userChanges
end

--[=[
	Sends the given repository changes to the data store and repository provided.

	This send operation is asynchronous, and will return a promise that will
	resolve when the data store has been updated. Exclusive write access to flags
	in the repository must be ensured before this function is called otherwise
	other server instances may overwrite the changes made by this server instance.

	@within Serialization
]=]
local function sendRepository(
	store: DataStore,
	name: string,
	changes: StoreTypes.RepositoryChanges
): PromiseTypes.Promise<nil>
	return Promise.new(function(resolve: (PromiseTypes.Promise<nil> | nil) -> ())
		store:UpdateAsync(name, function(repository: StoreTypes.Repository): StoreTypes.Repository
			return serializeRepository(repository, changes)
		end)
		resolve()
	end)
end

--[=[
	Sends the given flag changes for the serialization store provided.

	This send operation is asynchronous, and will return a promise that will
	resolve when the data store has been updated. This function will attempt to
	acquire exclusive write access to the flags in the data store before sending
	the flag changes provided. It will make changes to the index of the data store
	to ensure that the changes are consistent with the data store.

	@within Serialization
]=]
local function sendFlags(
	store: StoreTypes.SerializationStore,
	flagChanges: StoreTypes.FlagChanges
): PromiseTypes.Promise<nil>
	return Promise.new(
		function(resolve: (PromiseTypes.Promise<nil> | nil) -> (), _, onCancel: (() -> ()) -> ())
			local promises: { PromiseTypes.Promise<nil> } = {}

			onCancel(function()
				for _, promise in promises do
					promise:cancel()
				end
			end)

			local managedChanges, userChanges = sendFlagsToDirectory(store, flagChanges)

			for name, changes in managedChanges do
				local promise = sendRepository(store.managed, name, changes)
				table.insert(promises, promise)
			end

			for name, changes in userChanges do
				local promise = sendRepository(store.user, name, changes)
				table.insert(promises, promise)
			end

			resolve(Promise.all(promises))
		end
	)
end

return sendFlags
