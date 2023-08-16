local Package = script.Parent
local Signal = require(Package.Parent.Signal)

--[=[
	A rule set to determine if a feature should be active for a given context.

	When a rule set is evaluated against a context, all parts of the rule set must
	be true for this rule set to pass. If no rule sets match then this rule set
	will not apply. See [isActive](#isActive) for a more detailed explanation.

	AB testing segments are provided as a map of segment names to segment
	proportions. All testing segment proportions are added together when selecting
	a segment to determine the total proportion rather than using a percentage.
	This enables more specific and configurable group proportions than strict
	percentages may allow.

	```lua
	create("abTestFlag", {
		active: true,
		ruleSets: {
			{ -- Our AB testing rule set
				abSegments = {
					-- Our total proportion is 8, so we're selecting out of 8 total.
					segment1 = 5, -- This segment accounts for 5/8ths of the population.
					segment2 = 2, -- This segment accounts for 2/8ths, or 1/4th.
					segment3 = 1, -- This segment accounts for 1/8th.
				},
			},
		},
	})
	```

	.activation? ((context?: { [unknown]: unknown }, ruleSet?: { [unknown]: unknown }) -> boolean) -- A custom activation function to evaluate
	.allowedUsers? { [number]: true } -- A set of user IDs that must match
	.forbiddenUsers? { [number]: true } -- A set of user IDs that may not match
	.allowedGroups? { [string]: true } -- A set of groups that must match
	.forbiddenGroups? { [string]: true } -- A set of groups that may not much
	.allowedSystemStates? { [string]: true } -- A set of system states that must match
	.forbiddenSystemStates? { [string]: true } -- A set of system states that may not match
	.abSegments? { [string]: number } -- A map of AB testing segments

	@interface RuleSet
	@within FeatureFlags
]=]
export type RuleSet = {
	activation: ((context: { [unknown]: unknown }?, ruleSet: { [unknown]: unknown }?) -> boolean)?,
	allowedUsers: { [number]: true }?,
	forbiddenUsers: { [number]: true }?,
	allowedGroups: { [string]: true }?,
	forbiddenGroups: { [string]: true }?,
	allowedSystemStates: { [string]: true }?,
	forbiddenSystemStates: { [string]: true }?,
	abSegments: { [string]: number }?,
}

--[=[
	The configuration of a flag.

	Rule sets will be evaluated one at a time to determine if an activation
	context should have this feature active. See [isActive](#isActive) for a more
	detailed explanation.

	The configuration additionally includes all [RuleSet] properties and can be
	used as a primary rule set. This rule set, when used this way, is guaranteed
	to be evaluated first. This is useful if there is a common rule set that is
	more important, is a hot path, or if there is only one rule set.

	:::info
	The active property controls whether this flag can be active for anyone. If
	this is false, no one will have this feature active. If a flag should be
	active in some circumstances, use rule sets.
	:::

	.active boolean -- Whether the flag is active
	.ruleSets? { RuleSet } -- Rule sets to evaluate for this configuration

	@interface FlagConfig
	@within FeatureFlags
]=]
export type FlagConfig = {
	active: boolean,
	ruleSets: { RuleSet }?,
} & RuleSet

--[=[
	All data associated with a flag.

	.config FlagConfig -- The configuration for this flag
	.retired boolean -- Whether this flag is retired

	@interface FlagData
	@within FeatureFlags
]=]
export type FlagData = {
	config: FlagConfig,
	retired: boolean,
}

--[=[
	A record of how a flag has changed.

	.old? FlagData -- The old flag, or nil if the flag was just created
	.new? FlagData -- The new flag, or nil if the flag no longer exists

	@interface ChangeRecord
	@within FeatureFlags
]=]
export type ChangeRecord = {
	old: FlagData?,
	new: FlagData?,
}

--[=[
	The Flags auxiliary functions.

	@class Flags
	@ignore
]=]
local flags: { [string]: FlagData } = {}

--[=[
	The flag changed event.

	This fires every time a flag changes. It provides the name and a
	[ChangeRecord].

	```lua
	Changed:Connect(function(name: string, record: ChangeRecord)
		print(string.format("Flag '%s' changed.", name))
		print("Old flag:", record.old)
		print("New flag:", record.new)
	end)
	```

	@prop Changed Event
	@within FeatureFlags
]=]
local Changed = Signal.new()

--[=[
	Fires a Changed event for a flag.

	@within Flags
]=]
local function fireChange(name: string, old: FlagData?, new: FlagData?)
	local record: ChangeRecord = {
		old = old,
		new = new,
	}
	Changed:Fire(name, record)
end

--[=[
	Creates new FlagData.

	@within Flags
]=]
local function newFlag(config: FlagConfig, retired: boolean?): FlagData
	return table.freeze({
		config = config,
		retired = if retired ~= nil then retired else false,
	})
end

type PartialFlag = {
	config: FlagConfig?,
	retired: boolean?,
}

--[=[
	Creates a new, updated flag from partial flag data.

	@within Flags
]=]
local function updateFlag(flag: FlagData, update: PartialFlag): FlagData
	return newFlag(
		if update.config then update.config else flag.config,
		if update.retired ~= nil then update.retired else flag.retired
	)
end

--[=[
	Creates a new flag with the provided name and configuration.

	:::note
	This only needs to be used when introducing new flags, such as when you want
	to introduce a new flag for a feature ahead of time.

	This is typically done through some configuration interface, such as the built
	in one.
	:::

	:::tip
	If updating a flag that already exists, use the `update` function instead.
	:::

	@param name -- The name to use for the flag
	@param config -- The configuration of this flag
	@param retired? boolean -- Whether this flag is retied

	@error "Flag '%s' already exists." -- Thrown when a flag with this name already exists.

	@within FeatureFlags
]=]
local function create(name: string, config: FlagConfig, retired: boolean?)
	if flags[name] then
		error(string.format("Flag '%s' already exists.", name))
	end

	local flag = newFlag(config, retired)
	flags[name] = flag

	fireChange(name, nil, flag)
end

--[=[
	Checks if a flag with this name currently exists.

	@within FeatureFlags
]=]
local function exists(name: string): boolean
	return flags[name] ~= nil
end

--[=[
	Reads the data of this flag.

	This is primarily useful to display or manipulate flag information.

	:::caution
	This shouldn't be used to determine flag activation. Use the `isActive`
	function instead.

	While this contains all flag information, it doesn't include any complex
	activation evaluation logic that `isActive` does.
	:::

	@error "Flag '%s' doesn't exist." -- Thrown when a flag with this name doesn't exist.

	@within FeatureFlags
]=]
local function read(name: string): FlagData
	local flag = flags[name]
	if not flag then
		error(string.format("Flag '%s' doesn't exist.", name))
	end
	return flag
end

--[=[
	Updates the configuration of this flag.

	@error "Flag '%s' doesn't exist." -- Thrown when a flag with this name doesn't exist.

	@within FeatureFlags
]=]
local function update(name: string, config: FlagConfig)
	local oldFlag = read(name)
	local newFlag = updateFlag(oldFlag, { config = config })
	flags[name] = newFlag

	fireChange(name, oldFlag, newFlag)
end

--[=[
	Sets the retired status of a flag.

	If a retired status isn't provided it defaults to true, assuming you intend to
	retire a flag.

	@param retired? boolean -- The retired status of the flag

	@error "Flag '%s' doesn't exist." -- Thrown when a flag with this name doesn't exist.

	@within FeatureFlags
]=]
local function retire(name: string, retired: boolean?)
	local retired = if retired ~= nil then retired else true
	local oldFlag = read(name)
	local newFlag = updateFlag(oldFlag, { retired = retired })
	flags[name] = newFlag

	fireChange(name, oldFlag, newFlag)
end

--[=[
	Removes a flag entirely.

	@error "Flag '%s' doesn't exist." -- Thrown when a flag with this name doesn't exist.

	@within FeatureFlags
]=]
local function destroy(name: string)
	local oldFlag = read(name)
	flags[name] = nil

	fireChange(name, oldFlag)
end

--[=[
	Resets all registered flags.

	After this operation, there will be no registered flags and flags will need to
	be registered again before they can be used. This is primarily used to
	re-initialize all feature flags.

	Notification will inform all listeners about the removal of all flags.
	Performing no notification is faster, but may break features currently
	listening. The default is not to notify, assuming that features listening to
	flags have already been handled or are not currently listening.

	@param notify? boolean -- Whether to notify listeners of this change

	@within FeatureFlags
]=]
local function reset(notify: boolean?)
	local notify = if notify ~= nil then notify else false
	if notify then
		local oldFlags = flags
		flags = {}

		for name, flag in oldFlags do
			fireChange(name, flag)
		end
	else
		table.clear(flags)
	end
end

return {
	create = create,
	exists = exists,
	read = read,
	update = update,
	retire = retire,
	destroy = destroy,
	reset = reset,

	Changed = Changed,
}
