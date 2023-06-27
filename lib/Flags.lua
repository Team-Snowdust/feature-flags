local Package = script.Parent
local Signal = require(Package.Signal)

--[=[
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
	@within FeatureFlags
]=]
export type FlagConfig = {
	active: boolean,
	ruleSets: { RuleSet }?,
} & RuleSet

--[=[
	@within FeatureFlags
]=]
export type FlagData = {
	config: FlagConfig,
	retired: boolean,
}

--[=[
	@within FeatureFlags
]=]
export type ChangeRecord = {
	old: FlagData?,
	new: FlagData?,
}

--[=[
	@within FeatureFlags
]=]
local Changed = Signal.new()
local flags: { [string]: FlagData } = {}

--[=[
	@ignore
]=]
local function fireChange(name: string, old: FlagData?, new: FlagData?)
	local record: ChangeRecord = {
		old = old,
		new = new,
	}
	Changed:Fire(name, record)
end

--[=[
	@ignore
]=]
local function newFlag(config: FlagConfig, retired: boolean?): FlagData
	return table.freeze({
		-- table.freeze seems to break this type. We need to reassert that this is,
		-- in fact, still a FlagConfig.
		config = table.freeze(config) :: FlagConfig,
		retired = if retired ~= nil then retired else false,
	})
end

type PartialFlag = {
	config: FlagConfig?,
	retired: boolean?,
}

--[=[
	@ignore
]=]
local function updateFlag(flag: FlagData, update: PartialFlag): FlagData
	return newFlag(
		if update.config then update.config else flag.config,
		if update.retired ~= nil then update.retired else flag.retired
	)
end

--[=[
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
	@within FeatureFlags
]=]
local function exists(name: string): boolean
	return flags[name] ~= nil
end

--[=[
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
	@within FeatureFlags
]=]
local function update(name: string, config: FlagConfig)
	local oldFlag = read(name)
	local newFlag = updateFlag(oldFlag, { config = config })
	flags[name] = newFlag

	fireChange(name, oldFlag, newFlag)
end

--[=[
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
	@within FeatureFlags
]=]
local function destroy(name: string)
	local oldFlag = read(name)
	flags[name] = nil

	fireChange(name, oldFlag)
end

--[=[
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
