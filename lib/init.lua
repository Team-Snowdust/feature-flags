local Flags = require(script.Flags)
local get = require(script.get)
local isActive = require(script.isActive)

--[=[
	@class FeatureFlags
]=]

export type ActivationConfig = isActive.ActivationConfig
export type ActivationContext = isActive.ActivationContext
export type ChangeRecord = Flags.ChangeRecord
export type UpdateOptions = Flags.UpdateOptions
export type PartialUpdateOptions = Flags.PartialUpdateOptions
export type FlagConfig = Flags.FlagConfig
export type PartialFlagConfig = Flags.PartialFlagConfig
export type RuleSet = Flags.RuleSet
export type Flag = get.Flag

return {
	create = Flags.create,
	exists = Flags.exists,
	read = Flags.read,
	update = Flags.update,
	retire = Flags.retire,
	destroy = Flags.destroy,
	reset = Flags.reset,

	Changed = Flags.Changed.Event,

	get = get,
	isActive = isActive,

	-- init = init,
	-- config = config,

	-- getAllFlags = getAllFlags,
	-- getAuditLog = getAuditLog,
}
