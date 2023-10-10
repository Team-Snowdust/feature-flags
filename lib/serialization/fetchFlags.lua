local Serialization = script.Parent
local Package = Serialization.Parent
local PromiseTypes = require(Package.types.Promise)
local StoreTypes = require(Serialization.types.store)

local Promise = require(Package.Parent.Promise) :: PromiseTypes.PromiseStatic
local deserializeRepository = require(script.Parent.deserializeRepository)

--[=[
	Fetches the given repository from the data store provided.

	This fetch operation is asynchronous, and will return a promise that will
	resolve when the flag changes in the repository have been synchronized.

	@within Serialization
]=]
local function fetchRepository(
	repositoryStore: DataStore,
	name: string,
	flags: StoreTypes.RepositoryFlags
): PromiseTypes.Promise<nil>
	return Promise.new(function(resolve: (PromiseTypes.Promise<nil> | nil) -> ())
		local repository: StoreTypes.Repository = repositoryStore:GetAsync(name)
		deserializeRepository(repository, flags)
		resolve()
	end)
end

--[=[
	Fetches all of the flag changes from the data store provided.

	This fetch operation is asynchronous, and will return a promise that will
	resolve when all of the flag changes have been synchronized.

	@within Serialization
]=]
local function fetchFlags(store: StoreTypes.SerializationStore): PromiseTypes.Promise<nil>
	return Promise.new(
		function(resolve: (PromiseTypes.Promise<nil> | nil) -> (), _, onCancel: (() -> ()) -> ())
			local promises: { PromiseTypes.Promise<nil> } = {}

			onCancel(function()
				for _, promise in promises do
					promise:cancel()
				end
			end)

			for name, flags in store.managedUpdates do
				local promise = fetchRepository(store.managed, name, flags):andThen(function()
					store.managedUpdates[name] = nil
				end)
				table.insert(promises, promise)
			end

			for name, flags in store.userUpdates do
				local promise = fetchRepository(store.user, name, flags):andThen(function()
					store.userUpdates[name] = nil
				end)
				table.insert(promises, promise)
			end

			resolve(Promise.all(promises))
		end
	)
end

return fetchFlags
