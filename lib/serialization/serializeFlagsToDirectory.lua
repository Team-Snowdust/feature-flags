local Serialization = script.Parent
local StoreTypes = require(Serialization.types.store)

local MAXIMUM_FLAGS_PER_REPOSITORY = 1024

--[=[
	Flushes the repository cache.

	This should be called when the directory is updated to ensure that the
	repository cache is up-to-date.

	@function flushRepositoryCache
	@within Serialization
]=]
local flushRepositoryCache: () -> ()

--[=[
	Selects a repository for the given directory.

	This will select a repository that has less than the maximum number of flags
	per repository. If no such repository exists, it will create a new one. This
	will always return a valid repository name with available space.

	This will update the repository cache if it has not been built yet. This
	allows this function to be called multiple times without rebuilding the
	repository cache, which can be expensive.

	@function selectRepository
	@within Serialization
]=]
local selectRepository: (directory: StoreTypes.Directory) -> string

do
	local repositorySize: { [string]: number } = {}
	local partialRepositories: { [string]: true } = {}
	local largestRepository = -1
	local repositoryCacheBuilt = false

	--[=[
		Builds the repository cache for the given directory.

		This cache is used to determine which repository to use when serializing
		flags to the directory. This tracks the number of flags in each repository
		and the number of repositories that have less than the maximum number of
		flags.

		@within Serialization
	]=]
	local function buildRepositoryCache(directory: StoreTypes.Directory)
		if repositoryCacheBuilt then
			return
		end
		repositoryCacheBuilt = true

		for _, entry in directory do
			local repositoryName = entry.repository
			local numeral = tonumber(repositoryName)
			if numeral and numeral > largestRepository then
				largestRepository = numeral
			end

			if not repositorySize[repositoryName] then
				repositorySize[repositoryName] = 1
				continue
			end

			repositorySize[repositoryName] += 1
		end

		for name, size in repositorySize do
			if size < MAXIMUM_FLAGS_PER_REPOSITORY then
				partialRepositories[name] = true
			end
		end
	end

	function flushRepositoryCache()
		table.clear(repositorySize)
		table.clear(partialRepositories)
		largestRepository = -1
		repositoryCacheBuilt = false
	end

	function selectRepository(directory: StoreTypes.Directory): string
		buildRepositoryCache(directory)
		local name = next(partialRepositories)

		if not name then
			largestRepository += 1
			name = tostring(largestRepository)
			partialRepositories[name] = true
			repositorySize[name] = 1
		else
			repositorySize[name] += 1
		end

		if repositorySize[name] == MAXIMUM_FLAGS_PER_REPOSITORY then
			partialRepositories[name] = nil
		end

		return name
	end
end

--[=[
	Serializes the given flag changes to the directory provided.

	This will update the directory with the changes provided. It will also
	return the changes that should be sent to the data store for the managed
	flags and user flags.

	@within Serialization
]=]
local function serializeFlagsToDirectory(
	old: StoreTypes.Directory,
	new: StoreTypes.Directory,
	flagChanges: StoreTypes.FlagChanges
): (
	StoreTypes.Directory,
	StoreTypes.RepositoryChanges,
	StoreTypes.RepositoryChanges
)
	local managedChanges: StoreTypes.RepositoryChanges = {}
	local userChanges: StoreTypes.RepositoryChanges = {}
	flushRepositoryCache()

	for name, change in flagChanges do
		local cachedEntry = old[name]
		local entry = new[name]

		if not cachedEntry then
			cachedEntry = {
				repository = "unknown",
				managed = true,
				version = 0,
			}
			old[name] = cachedEntry
		else
			cachedEntry.version += 1
		end

		if not entry then
			entry = cachedEntry
			entry.repository = selectRepository(new)
			new[name] = entry
		else
			cachedEntry.repository = entry.repository
			cachedEntry.managed = entry.managed

			if entry.version >= cachedEntry.version then
				cachedEntry.version = entry.version
				warn(
					string.format(
						"Flag '%s' was found with a later version and will not be updated.",
						name
					)
				)
				continue
			end

			entry.version = cachedEntry.version
		end

		change.version = entry.version

		local updates
		if entry.managed then
			updates = managedChanges
		else
			updates = userChanges
		end

		local repository = updates[entry.repository]

		if not repository then
			repository = {}
			updates[entry.repository] = repository
		end

		repository[name] = change
	end

	return new, managedChanges, userChanges
end

return serializeFlagsToDirectory
