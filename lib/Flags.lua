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

	:::info
	The active property controls whether this flag can be active for anyone. If
	this is false, no one will have this feature active. If a flag should be
	active in some circumstances, use rule sets.
	:::

	.active boolean -- Whether the flag is active
	.retired boolean -- Whether this flag is retired
	.ruleSets { RuleSet } -- Rule sets to evaluate for this configuration

	@interface FlagConfig
	@within FeatureFlags
]=]
export type FlagConfig = {
	active: boolean,
	retired: boolean,
	ruleSets: { RuleSet },
}

--[=[
	A partial flag configuration.

	This is used to update a flag. Any properties that are nil will not be
	updated.

	.active? boolean -- Whether the flag is active
	.retired? boolean -- Whether this flag is retired
	.ruleSets? { RuleSet } -- Rule sets to evaluate for this configuration

	@interface PartialFlagConfig
	@within FeatureFlags
]=]
export type PartialFlagConfig = {
	active: boolean?,
	retired: boolean?,
	ruleSets: { RuleSet }?,
}

--[=[
	A record of how a flag has changed.

	.old? FlagConfig -- The old flag, or nil if the flag was just created
	.new? FlagConfig -- The new flag, or nil if the flag no longer exists

	@interface ChangeRecord
	@within FeatureFlags
]=]
export type ChangeRecord = {
	old: FlagConfig?,
	new: FlagConfig?,
}

--[=[
	Options for updating a flag.

	These are options for how a flag should be updated. Here you can specify
	whether this change should be serialized. The default is false.

	.serialize boolean -- Whether this change should be serialized

	@interface UpdateOptions
	@within FeatureFlags
]=]
export type UpdateOptions = {
	serialize: boolean,
}

--[=[
	Partial update options.

	This is used to configure a flag update. Any properties that are nil will be
	given default values.

	.serialize? boolean -- Whether this change should be serialized

	@interface PartialUpdateOptions
	@within FeatureFlags
]=]
export type PartialUpdateOptions = {
	serialize: boolean?,
}

--[=[
	The Flags auxiliary functions.

	@class Flags
	@ignore
]=]
local flags: { [string]: FlagConfig } = {}

--[=[
	The flag changed event.

	This fires every time a flag changes. It provides the name, a [ChangeRecord],
	and [UpdateOptions].

	```lua
	Changed:Connect(function(name: string, record: ChangeRecord, options: UpdateOptions)
		print(string.format("Flag '%s' changed.", name))
		print("Old flag:", record.old)
		print("New flag:", record.new)
		if options.serialize then
			print("This change will be serialized.")
		end
	end)
	```

	@prop Changed Event
	@within FeatureFlags
]=]
local Changed = Signal.new()

--[=[
	Normalizes partial update options.

	@within Flags
]=]
local function normalizeUpdateOptions(options: PartialUpdateOptions?): UpdateOptions
	return {
		serialize = if options and options.serialize ~= nil then options.serialize else false,
	}
end

--[=[
	Fires a Changed event for a flag.

	@within Flags
]=]
local function fireChange(
	name: string,
	old: FlagConfig?,
	new: FlagConfig?,
	options: PartialUpdateOptions?
)
	local record: ChangeRecord = {
		old = old,
		new = new,
	}
	Changed:Fire(name, record, normalizeUpdateOptions(options))
end

--[=[
	Creates a new, updated flag from partial flag data.

	@within Flags
]=]
local function updateConfig(flag: FlagConfig, update: PartialFlagConfig): FlagConfig
	return {
		active = if update.active ~= nil then update.active else flag.active,
		retired = if update.retired ~= nil then update.retired else flag.retired,
		ruleSets = if update.ruleSets then update.ruleSets else flag.ruleSets,
	}
end

local DefaultConfig: FlagConfig = {
	active = true,
	retired = false,
	ruleSets = {},
}

--[=[
	Normalizes a partial flag configuration.

	@within Flags
]=]
local function normalizeConfig(config: PartialFlagConfig?): FlagConfig
	return updateConfig(DefaultConfig, config or {})
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

	@error "Flag '%s' already exists." -- Thrown when a flag with this name already exists.

	@within FeatureFlags
]=]
local function create(name: string, config: PartialFlagConfig?, options: PartialUpdateOptions?)
	if flags[name] then
		error(string.format("Flag '%s' already exists.", name))
	end

	local flag = normalizeConfig(config)
	flags[name] = flag

	fireChange(name, nil, flag, options)
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
local function read(name: string): FlagConfig
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
local function update(name: string, config: PartialFlagConfig, options: PartialUpdateOptions?)
	local oldFlag = read(name)
	local newFlag = updateConfig(oldFlag, config)
	flags[name] = newFlag

	fireChange(name, oldFlag, newFlag, options)
end

--[=[
	Sets the retired status of a flag.

	If a retired status isn't provided it defaults to true, assuming you intend to
	retire a flag.

	@param retired? boolean -- The retired status of the flag

	@error "Flag '%s' doesn't exist." -- Thrown when a flag with this name doesn't exist.

	@within FeatureFlags
]=]
local function retire(name: string, retired: boolean?, options: PartialUpdateOptions?)
	local retired = if retired ~= nil then retired else true
	local oldFlag = read(name)
	local newFlag = updateConfig(oldFlag, { retired = retired })
	flags[name] = newFlag

	fireChange(name, oldFlag, newFlag, options)
end

--[=[
	Removes a flag entirely.

	@error "Flag '%s' doesn't exist." -- Thrown when a flag with this name doesn't exist.

	@within FeatureFlags
]=]
local function destroy(name: string, options: PartialUpdateOptions?)
	local oldFlag = read(name)
	flags[name] = nil

	fireChange(name, oldFlag, nil, options)
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
