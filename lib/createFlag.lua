local Package = script.Parent
local Flags = require(Package.Flags)
local Signal = require(script.Parent.Signal)
local isActive = require(Package.isActive)

--[=[
	@class Flag
]=]
export type Flag = {
	name: string,
	create: (config: Flags.FlagConfig) -> (),
	read: () -> Flags.FlagData,
	update: (config: Flags.FlagConfig) -> (),
	retire: (retired: boolean?) -> (),
	destroy: () -> (),
	isActive: (context: isActive.ActivationContext?, config: isActive.ActivationConfig?) -> boolean,
	onChange: (callback: (record: Flags.ChangeRecord) -> ()) -> Signal.Connection,
}

--[=[
	@within Flag
	@ignore
]=]
local function createFlag(name: string): Flag
	return table.freeze({
		name = name,

		--[=[
			@within Flag
		]=]
		create = function(config: Flags.FlagConfig)
			Flags.create(name, config)
		end,

		--[=[
			@within Flag
		]=]
		read = function(): Flags.FlagData
			return Flags.read(name)
		end,

		--[=[
			@within Flag
		]=]
		update = function(config: Flags.FlagConfig)
			Flags.update(name, config)
		end,

		--[=[
			@within Flag
		]=]
		retire = function(retired: boolean?)
			Flags.retire(name, retired)
		end,

		--[=[
			@within Flag
		]=]
		destroy = function()
			Flags.destroy(name)
		end,

		--[=[
			@within Flag
		]=]
		isActive = function(
			context: isActive.ActivationContext?,
			config: isActive.ActivationConfig?
		): boolean
			return isActive(name, context, config)
		end,

		--[=[
			@within Flag
		]=]
		onChange = function(callback: (record: Flags.ChangeRecord) -> ()): Signal.Connection
			return Flags.Changed:Connect(function(changedName: string, record: Flags.ChangeRecord)
				if changedName == name then
					callback(record)
				end
			end)
		end,
	})
end

return createFlag
