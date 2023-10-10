local Serialization = script.Parent
local Package = Serialization.Parent
local Flags = require(Package.Flags)
local StoreTypes = require(Serialization.types.store)

--[=[
	This deserializes the given flags from the repository provided.

	@within Serialization
]=]
local function deserializeRepository(
	repository: StoreTypes.Repository,
	flags: StoreTypes.RepositoryFlags
)
	for flagName in flags do
		local flag = repository[flagName]
		if not flag then
			error(string.format("Flag '%s' not found in repository.", flagName))
		end

		if Flags.exists(flagName) then
			Flags.update(flagName, flag.config)
		else
			Flags.create(flagName, flag.config)
		end
	end
end

return deserializeRepository
