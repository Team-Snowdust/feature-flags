local Package = script.Parent
local Flags = require(Package.Flags)

local FLAG_EXISTS_ERROR = "Flag '%s' does not exist."
local FLAG_RETIRED_ERROR = "Flag '%s' is retired."

-- Large prime number for hash calculation. This only realistically needs to be
-- larger than the total proportion of all segments included. Around 1000 seems
-- like a reasonable value.
local AB_TESTING_PRIME = 1361

--[=[
	The ActivationContext for a feature' activation.

	Represents user ID, groups, system states, and AB segments that inform feature
	activation. These parameters allow features to operate under different rules
	based on their specific context.

	For instance, features may activate for specific user groups, AB segments, or
	under certain system states.

	Default behavior is applied if a context parameter is not provided.

	```lua
	local userContext = {
		userId = 12345, -- Replace with actual user ID
		groups = { betaTesters = true }, -- User is in the 'betaTesters' group
		systemStates = { lowLoad = true }, -- System is currently under low load
		abSegments = { testA = true }, -- User is in the 'testA' AB segment
	}

	if isActive("ourFeature", userContext) then
		-- Our feature is active for this particular context
	end
	```

	.userId number? -- The ID of the user
	.groups { [string]: true }? -- A set of groups
	.systemStates { [string]: true }? -- A set of system states
	.abSegments { [string]: true }? -- A set of AB segments

	@interface ActivationContext
	@within FeatureFlags
]=]
export type ActivationContext = {
	userId: number?,
	groups: { [string]: true }?,
	systemStates: { [string]: true }?,
	abSegments: { [string]: true }?,
}

--[=[
	The configuration parameters for a feature's activation.

	This determines the default state and warning behavior of a feature. This can
	assist with development of features behind flags, such as throwing errors when
	flags are being used that are no longer meant to be used.

	```lua
	if
		isActive("newUI", userContext, {
			default = true, -- Assume the feature is active if not found (do not notify)
			allowRetire = false, -- Notify if the flag has been retired
			warnRetire = false, -- Error if the flag is retired
		})
	then
		-- Load the new user interface
	else
		-- Load the old user interface
	end
	```

	.default boolean? -- Default activation status if the feature doesn't exist
	.allowRetire boolean? -- Flag to allow retirement of the feature; if not set and the flag is retired, this notifies in the console
	.warnExists boolean? -- Flag to warn rather than error when a feature doesn't exist
	.warnRetire boolean? -- Flag to warn rather than error when a feature is retired

	@interface ActivationConfig
	@within FeatureFlags
]=]
export type ActivationConfig = {
	default: boolean?,
	allowRetire: boolean?,
	warnExists: boolean?,
	warnRetire: boolean?,
}

--[=[
	The isActive auxiliary functions.

	@class isActive
	@ignore
]=]

--[=[
	Normalize the context provided.

	This ensures that all optional properties that can have defaults have a value.

	@within isActive
]=]
local function normalizeContext(context: ActivationContext?): ActivationContext
	-- TODO: Merge global context in
	return context or {}
end

--[=[
	A normalized ActivationContext.

	.default?: boolean
	.allowRetire: boolean
	.warnExists: boolean
	.warnRetire: boolean

	@interface ActivationContext
	@within isActive
]=]
type NormalizedConfig = {
	default: boolean?,
	allowRetire: boolean,
	warnExists: boolean,
	warnRetire: boolean,
}

--[=[
	Normalize the configuration provided.

	This ensures that all optional properties that can have defaults have a value.

	@within isActive
]=]
local function normalizeConfig(config: ActivationConfig?): NormalizedConfig
	-- TODO: Merge global config in
	return {
		default = if config and config.default ~= nil then config.default else nil,
		allowRetire = if config and config.allowRetire ~= nil then config.allowRetire else true,
		warnExists = if config and config.warnExists ~= nil then config.warnExists else false,
		warnRetire = if config and config.warnRetire ~= nil then config.warnRetire else true,
	}
end

--[=[
	Determines if two sets share any elements.

	@within isActive
]=]
local function hasIntersection<T>(left: { [T]: true }, right: { [T]: true }): boolean
	for element in left do
		if right[element] then
			return true
		end
	end
	return false
end

--[=[
	Hash a string into a number.

	@within isActive
]=]
local function hashCode(string: string): number
	local result = 0
	for i = 1, #string do
		local charCode = string.byte(string, i)
		result = (bit32.lshift(result, 5) - result) + charCode
	end
	return result
end

--[=[
	Evaluates a RuleSet.

	All rules in the set must pass for the RuleSet to pass. Some rules may not
	match within a RuleSet and these are ignored when determining if this RuleSet
	passes.

	@within isActive
]=]
local function evaluateRuleSet(context: ActivationContext, ruleSet: Flags.RuleSet): boolean?
	local matched = false

	-- Check user allowlist
	if ruleSet.allowedUsers and context.userId then
		if not ruleSet.allowedUsers[context.userId] then
			return false
		end
		matched = true
	end

	-- Check user blocklist
	if ruleSet.forbiddenUsers and context.userId then
		if ruleSet.forbiddenUsers[context.userId] then
			return false
		end
		matched = true
	end

	-- Check group allowlist
	if ruleSet.allowedGroups and context.groups then
		if not hasIntersection(context.groups, ruleSet.allowedGroups) then
			return false
		end
		matched = true
	end

	-- Check group blocklist
	if ruleSet.forbiddenGroups and context.groups then
		if hasIntersection(context.groups, ruleSet.forbiddenGroups) then
			return false
		end
		matched = true
	end

	-- Check system state allowlist
	if ruleSet.allowedSystemStates and context.systemStates then
		if not hasIntersection(context.systemStates, ruleSet.allowedSystemStates) then
			return false
		end
		matched = true
	end

	-- Check system state blocklist
	if ruleSet.forbiddenSystemStates and context.systemStates then
		if hasIntersection(context.systemStates, ruleSet.forbiddenSystemStates) then
			return false
		end
		matched = true
	end

	-- Check AB segment conditions
	if ruleSet.abSegments and context.abSegments and context.userId then
		-- Collect and sort the AB segments to ensure a deterministic order of
		-- evaluation
		local segments = {}
		local totalProportion = 0
		for name, proportion in ruleSet.abSegments do
			table.insert(segments, name)
			totalProportion += proportion
		end
		table.sort(segments)

		-- Calculate a hash value based on the segments in this test
		local testIdString = table.concat(segments, "_")
		local testId = hashCode(testIdString)

		local selectedSegment = ((testId + context.userId) * AB_TESTING_PRIME) % totalProportion

		local matchedABSegment = false
		local cumulativeProportion = 0
		for _, segment in segments do
			local proportion = ruleSet.abSegments[segment]
			local minimumProportion = cumulativeProportion
			cumulativeProportion += proportion

			local isInSegment = selectedSegment >= minimumProportion
				and selectedSegment < cumulativeProportion

			if isInSegment then
				if context.abSegments[segment] then
					matchedABSegment = true
				end
				break
			end
		end

		if not matchedABSegment then
			return false
		end
		matched = true
	end

	-- Check custom activation function
	if ruleSet.activation then
		if not ruleSet.activation(context, ruleSet) then
			return false
		end
		matched = true
	end

	if matched then
		return true
	end

	-- If no rules matched, the result is undecided
	return nil
end

--[=[
	Checks if a feature flag is active based on provided context and
	configuration.

	The `isActive` function evaluates whether a feature should be active based on
	the provided user context and configuration. It normalizes these inputs, using
	default values for any missing context or configuration properties.

	```lua
	if isActive("uiUpdate", {
		userId = 1000,
		groups = { beta = true },
		abSegments = { newInventory = true },
	}) then
		-- The user with this context should have this feature active.
	end
	```

	The feature flag's existence and retirement status are then checked:

	- If the feature doesn't exist, the behavior depends on the `warnExists` and
	  `default` configuration properties.

	  1. If `warnExists` is true, a warning is logged.
	  2. If `default` is provided, the `default` value is returned.
	  3. If neither a warning is logged nor a `default` value is provided, an
	     error is thrown.
	  4. If nothing else causes the function to terminate a default value of false
	     is returned.

	  ```lua
	  if isActive("missingFlag", activationContext, {
	  	default = true,
	  	warnExists = true,
	  }) then
	  	-- If the flag no longer exists we still execute this code.
	  	-- A warning is logged rather than an error.
	  else
	  	-- The flag exists, but is set to false.
	  end
	  ```

	- If the feature is retired, the behavior depends on the `allowRetire` and
	  `warnRetire` configuration properties.

	  1. If `allowRetire` is false, an error is thrown.
	  2. If `allowRetire` is true but `warnRetire` is true as well, a warning is
	     logged.

	  ```lua
	  if isActive("oldFlag", activationContext, {
	  	allowRetire = true,
	  	warnRetire = true,
	  }) then
	  	-- A retired flag can still be checked, but a warning is logged.
	  end
	  ```

	The flag's active status is then checked. If the flag isn't active, then false
	is returned immediately.

	:::info
	An inactive flag indicates it should not be active for anyone or under any
	circumstances. To activate a feature conditionally rule sets should be used.
	:::

	If the flag is active, each rule set in the feature flag's configuration is
	evaluated using the provided context:

	- If a rule set evaluates to true, the feature is active.
	- If no rule set evaluates to true, but at least one rule set was evaluated
	  (i.e., it matched the context even though it evaluated to false), the
	  feature is not active.
	- If no rule set matches the context (i.e., none of the rule sets were
	  evaluated), this means that no rules apply to disable a feature for the
	  provided context. The feature is considered active.

		:::caution
	  This is sometimes unintuitive for users unfamiliar with it.

	  Consider the case where a rule set to activate a feature for a specific user
	  ID is configured but the feature is being activated without a user context,
	  such as on the server. In such a case, the user restriction should not be
	  considered matching and the feature should be considered active if no other
	  rules apply.
		:::

	@param name -- The name of the feature flag to check
	@param context -- The user context for this feature activation
	@param config -- The configuration parameters for this feature activation

	@return boolean -- Whether the feature should be active

	@within FeatureFlags
]=]
local function isActive(
	name: string,
	context: ActivationContext?,
	config: ActivationConfig?
): boolean
	local context = normalizeContext(context)
	local config = normalizeConfig(config)

	-- Check if this flag exists and handle according to configuration.
	if not Flags.exists(name) then
		local notified = false
		if config.warnExists then
			notified = true
			warn(string.format(FLAG_EXISTS_ERROR, name))
		end

		if config.default ~= nil then
			return config.default
		-- Only notify once, whether that's a warning or error.
		elseif not notified then
			error(string.format(FLAG_EXISTS_ERROR, name))
		end

		return false
	end

	local flag = Flags.read(name)

	if flag.retired then
		if not config.allowRetire then
			error(string.format(FLAG_RETIRED_ERROR, name))
		end

		if config.warnRetire then
			warn(string.format(FLAG_RETIRED_ERROR, name))
		end
	end

	local flagConfig = flag.config

	if not flagConfig.active then
		return false
	end

	local mainEvaluation = evaluateRuleSet(context, config)
	if mainEvaluation ~= nil then
		return mainEvaluation
	end

	local evaluated = false
	for _, ruleSet in flagConfig.ruleSets or {} do
		local evaluation = evaluateRuleSet(context, ruleSet)
		if evaluation then
			return true
		end
		if evaluation ~= nil then
			evaluated = true
		end
	end

	return not evaluated
end

return isActive
