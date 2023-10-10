local Serialization = script.Parent
local StoreTypes = require(Serialization.types.store)
local deserializeDirectory = require(Serialization.deserializeDirectory)

--[=[
	Fetches the directory from the given directory store.

	This will return the directory and a table of updates to the directory since
	the last time it was fetched. The updates table will have updates to the user
	and managed repositories, as well as a set of removed flags.

	@within Serialization
]=]
local function fetchDirectory(
	directoryStore: DataStore,
	directory: StoreTypes.Directory
): (StoreTypes.Directory, {
	managed: StoreTypes.RepositoryUpdates,
	user: StoreTypes.RepositoryUpdates,
	removed: { [string]: true },
})
	local newDirectory: StoreTypes.Directory = directoryStore:GetAsync("flags")
	return newDirectory, deserializeDirectory(directory, newDirectory)
end

return fetchDirectory
