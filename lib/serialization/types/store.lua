local Serialization = script.Parent.Parent
local Package = Serialization.Parent
local Flags = require(Package.Flags)

export type DirectoryEntry = {
	repository: string,
	managed: boolean,
	version: number,
}

export type Directory = { [string]: DirectoryEntry }
export type RepositoryFlags = { [string]: number }
export type RepositoryUpdates = { [string]: RepositoryFlags }

export type SerializationStore = {
	index: DataStore,
	managed: DataStore,
	user: DataStore,

	directory: Directory,

	managedUpdates: RepositoryUpdates,
	userUpdates: RepositoryUpdates,
}

export type Flag = {
	config: Flags.FlagConfig,
	version: number,
}

export type Repository = {
	[string]: Flag,
}

export type FlagChange = {
	change: Flags.FlagConfig?,
}

export type FlagChanges = { [string]: FlagChange }

export type VersionedChange = FlagChange & {
	version: number,
}

export type RepositoryChanges = { [string]: VersionedChange }

return nil
