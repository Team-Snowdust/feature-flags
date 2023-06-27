local Flags = require(script.Flags)
local get = require(script.get)
local isActive = require(script.isActive)

--[=[
	@class FeatureFlags
]=]

return {
	create = Flags.create,
	exists = Flags.exists,
	read = Flags.read,
	update = Flags.update,
	retire = Flags.retire,
	destroy = Flags.destroy,
	reset = Flags.reset,

	get = get,
	Changed = Flags.Changed.Event,
	isActive = isActive,

	-- init = init,
	-- config = config,

	-- getAllFlags = getAllFlags,
	-- getAuditLog = getAuditLog,
}
