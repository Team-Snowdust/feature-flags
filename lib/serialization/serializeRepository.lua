local Serialization = script.Parent
local StoreTypes = require(Serialization.types.store)

--[=[
	This serializes the given repository changes to the given repository.

	@within Serialization
]=]
local function serializeRepository(
	repository: StoreTypes.Repository,
	changes: StoreTypes.RepositoryChanges
): StoreTypes.Repository
	for name, change in changes do
		repository[name] = {
			config = change.change,
			version = change.version,
		}
	end

	return repository
end

return serializeRepository
