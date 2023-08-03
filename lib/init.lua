local Flags = require(script.Flags)
local get = require(script.get)
local isActive = require(script.isActive)

--[=[
	@class FeatureFlags
]=]

export type ActivationConfig = isActive.ActivationConfig
export type ActivationContext = isActive.ActivationContext
export type ChangeRecord = Flags.ChangeRecord
export type FlagConfig = Flags.FlagConfig
export type FlagData = Flags.FlagData
export type RuleSet = Flags.RuleSet

return {
	create = Flags.create,
	exists = Flags.exists,
	read = Flags.read,
	update = Flags.update,
	retire = Flags.retire,
	destroy = Flags.destroy,
	reset = Flags.reset,

	get = get,
	isActive = isActive,

	Changed = Flags.Changed.Event,

	-- init = init,
	-- config = config,

	-- getAllFlags = getAllFlags,
	-- getAuditLog = getAuditLog,
}
