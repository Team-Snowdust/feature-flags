local Serialization = script.Parent
local StoreTypes = require(Serialization.types.store)

--[=[
	This deserializes the given directory changes based on the new and prior state
	of the directory.

	This provides a set of updates to the managed and user repositories, as well
	as a set of removed flags.

	@within Serialization
]=]
local function deserializeDirectory(
	old: StoreTypes.Directory,
	new: StoreTypes.Directory
): {
	managed: StoreTypes.RepositoryUpdates,
	user: StoreTypes.RepositoryUpdates,
	removed: { [string]: true },
}
	local managedUpdates: StoreTypes.RepositoryUpdates = {}
	local userUpdates: StoreTypes.RepositoryUpdates = {}

	for flag, entry in new do
		local updates
		if entry.managed then
			updates = managedUpdates
		else
			updates = userUpdates
		end

		if not old[flag] or old[flag].version ~= entry.version then
			local repository = updates[entry.repository]
			if not repository then
				repository = {}
				updates[entry.repository] = repository
			end
			repository[flag] = entry.version
		end
	end

	local removed: { [string]: true } = {}
	for flag in old do
		if not new[flag] then
			removed[flag] = true
		end
	end

	return {
		managed = managedUpdates,
		user = userUpdates,
		removed = removed,
	}
end

return deserializeDirectory
