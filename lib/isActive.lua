local Package = script.Parent
local Flags = require(Package.Flags)

local FLAG_EXISTS_ERROR = "Flag '%s' does not exist."
local FLAG_RETIRED_ERROR = "Flag '%s' is retired."

-- Large prime number for hash calculation. This only realistically needs to be
-- larger than the total proportion of all segments included. Around 1000 seems
-- like a reasonable value.
local AB_TESTING_PRIME = 1361

--[=[
	The activation context.

	.userId number?
	.groups { [string]: true }?
	.systemStates { [string]: true }?
	.abSegments { [string]: true }?

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
	The activation configuration.

	.default boolean?
	.allowRetire boolean?
	.warnExists boolean?
	.warnRetire boolean?

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
	@class isActive
	@ignore
]=]

type NormalizedContext = {
	userId: number?,
	groups: { [string]: true },
	systemStates: { [string]: true },
}

--[=[
	Normalize the context provided.

	This ensures that all optional properties that can have defaults have a value.

	@within isActive
	@ignore
]=]
local function normalizeContext(context: ActivationContext?): NormalizedContext
	-- TODO: Merge global context in
	return {
		userId = if context and context.userId then context.userId else nil,
		groups = if context and context.groups then context.groups else {},
		systemStates = if context and context.systemStates then context.systemStates else {},
	}
end

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
	@ignore
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
	@ignore
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
	@ignore
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
	@ignore
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
	Determines if a flag should be active based on the provided context.

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
