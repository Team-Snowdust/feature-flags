---
sidebar_position: 1
---

# Client-Server Communication

Setting up robust communication between client and server for feature flags can
be daunting. While our library doesn't handle this out-of-the-box, there's a
good reason: we want to ensure flexibility and give you control. This guide will
provide best practices and step-by-step instructions on achieving seamless
client-server communication for your feature flags.

## Step 1: Decide What Needs Communication

Not all flags should be sent to the client.

- **Server-Only Flags**: These flags are only relevant to server operations.
- **Sensitive Flags**: If a flag contains configurations or data that shouldn't
  be publicly accessible, keep it on the server.

### Rationale

Why doesn't the library handle this for you?

- **Flexibility**: Not all feature flags are meant for client-side visibility.
  Some may be server-side only, while others are crucial for client operations.
  By not automatically sending all flags to the client, we give developers the
  discretion to choose which flags to transmit.
- **Data Privacy**: Not every flag should be visible to the client, especially
  if it contains sensitive information or configurations.
- **Efficiency**: Automatically sending all flags can be a waste of bandwidth
  and resources, especially if many flags are not pertinent to the client.

## Step 2: Use the `Changed` Event

Efficiently listen to flag changes with the `Changed` event.

Whenever a feature flag is updated, the library emits a `Changed` event. Attach
a listener to this event to detect and manage updates efficiently.

```lua
FeatureFlags.Changed:Connect(function(name, record)
	-- Handle the flag change here
end)
```

## Step 3: Choose a Communication Method

Consider your game's needs and the number of flags when choosing a method. We
recommend the **Remote Events** method for its clarity and straightforward
implementation.

### Method A: Using Remote Events (Recommended)

Perfect for dynamic datasets and games with a larger number of flags.

First, we need to transmit flags to the client.

```lua title="transmitFlags.server.lua"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlagEvent = Instance.new("RemoteEvent")
FlagEvent.Name = "FlagEvent"
FlagEvent.Parent = ReplicatedStorage

-- Transmit flag changes to the client
FeatureFlags.Changed:Connect(function(name, record)
	FlagEvent:FireAllClients(name, record.new)
end)

-- Transmit existing flags to the client
Players.PlayerAdded:Connect(function(player)
	for name, flag in FeatureFlags.getAllFlags() do
		FlagEvent:FireClient(player, name, flag)
	end
end)
```

Then, we find the event on the client and receive the flag changes.

```lua title="receiveFlags.client.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlagEvent = ReplicatedStorage:WaitForChild("FlagEvent")

-- Listen for flag events
FlagEvent.OnClientEvent:Connect(function(name, data)
	if data then
		if FeatureFlags.exists(name) then
			FeatureFlags.update(name, data)
		else
			FeatureFlags.create(name, data)
		end
	else
		FeatureFlags.delete(name)
	end
end)
```

### Method B: Transmitting Flags as Attributes (Alternative)

This method can be useful in certain scenarios but comes with added intricacies.
Ensure you understand its workings fully before adopting.

First, we create our attribute serialization logic.

```lua title="Serialize.lua"
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Prefix = "flag"
local PrefixFormat = string.format("%s_%s", Prefix, "%s")

-- Serialize and write a flag to the Workspace
local function writeFlag(name, flag)
	Workspace:SetAttribute(string.format(PrefixFormat, name), HttpService:JSONEncode(flag))
end

-- Read and deserialize flag data
local function readFlag(flagData)
	return HttpService:JSONDecode(flagData)
end

-- Read and deserialize a flag from the Workspace
local function readFlagByName(name)
	return readFlag(Workspace:GetAttribute(string.format(PrefixFormat, name)))
end

return {
	Prefix = Prefix,
	PrefixFormat = PrefixFormat,

	writeFlag = writeFlag,
	readFlag = readFlag,
	readFlagByName = readFlagByName,
}
```

Next, we need to transmit flags to the client using the serialization we wrote.

```lua title="transmitFlags.server.lua"
local Serialize = require(script.Parent.Serialize)

-- Transmit flag changes to the client
FeatureFlags.Changed:Connect(function(name, record)
	Serialize.writeFlag(name, record.new)
end)

-- Transmit existing flags to the client
for name, flag in FeatureFlags.getAllFlags() do
	Serialize.writeFlag(name, flag)
end
```

Finally, we receive flags on the client using our serialization.

```lua title="receiveFlags.client.lua"
local Workspace = game:GetService("Workspace")
local Serialize = require(script.Parent.Serialize)

-- Handle any attributes
local function handleAttribute(name, value)
	local prefix, key = string.match(name, "^([^_]+)_(.+)$")

	if prefix == Serialize.Prefix then
		-- Receive flag changes
		local flagName = key

		if value then
			local flag = Serialize.read(value)

			if FeatureFlags.exists(flagName) then
				FeatureFlags.update(flagName, flag)
			else
				FeatureFlags.create(flagName, flag)
			end
		else
			FeatureFlags.delete(flagName)
		end
	elseif ... then
		-- Handle other unrelated attribute changes
	end
end

-- Listen for attribute changes
Workspace.AttributeChanged:Connect(function(name)
	handleAttribute(name, Workspace:GetAttribute(name))
end)

-- Receive existing attributes
for name, value in Workspace:GetAttributes() do
	handleAttribute(name, value)
end
```

## Step 4: Handling Activation Functions

Always ensure the client is aware of how to handle activation functions, as
these can't be directly serialized.

If your flags contain activation functions, they need special treatment.
Consider sending a signal or a specific data structure to inform the client when
they need to execute a specific predefined function.

### How to Pass Activation Functions

The key challenge with activation functions is that they aren't directly
serializable. However, a viable approach involves the use of a reference system.
Rather than passing the function, you pass an identifier for the function. The
client-side should have a corresponding set of functions to match these
identifiers.

First, we need a shared module defining the activation functions.

```lua title="ActivationFunctions.lua"
-- Require all necessary activation functions
...

-- Define a dictionary of function identifiers to functions
local activationFunctions = {
	increasedSpeed = increasedSpeed,
	networkCheck = networkCheck,
}

-- Define the inverse lookup table
local activationFunctionsInverse = {}
for name, value in activationFunctions do
	activationFunctionsInverse[value] = name
end

return {
	ToFunction = activationFunctions,
	ToIdentifier = activationFunctionsInverse,
}
```

Then, we can use this when we transmit our flags.

```lua title="transmitFlags.server.lua"
-- All previous imports

local ActivationFunctions = require(ReplicatedStorage.ActivationFunctions)

-- Snip

FeatureFlags.Changed:Connect(function(name, record)
	local transmissionRecord = clone(record.new)

	-- Convert the activation functions to identifiers
	for _, ruleSet in transmissionRecord.ruleSets do
		if ruleSet.activation then
			ruleSet.activation = ActivationFunctions.ToIdentifier[ruleSet.activation]
		end
	end

	FlagEvent:FireAllClients(name, transmissionRecord)
end)

-- Snip
```

And also when we receive our flags.

```lua title="receiveFlags.client.lua"
-- All previous imports

local ActivationFunctions = require(ReplicatedStorage.ActivationFunctions)

-- Snip

FlagEvent.OnClientEvent:Connect(function(name, data)
	if data then
		-- Convert the activation identifiers into functions
		for _, ruleSet in data.ruleSets do
			if ruleSet.activation then
				ruleSet.activation = ActivationFunctions.ToFunction[ruleSet.activation]
			end
		end

		-- Snip
	end
end)
```
