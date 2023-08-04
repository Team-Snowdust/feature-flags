---
sidebar_position: 1
---

# Getting Started

Feature Flags is a Luau feature flags library for _Roblox_.

This guide will help you get started with Feature Flags by walking you through
the process of installing it and using it in your projects.

## Installation

To use Feature Flags, you need to include it as a dependency in your
`wally.toml` file. Feature Flags can then be installed with [Wally].

```toml
FeatureFlags = "team-snowdust/feature-flags@0.1.0"
```

[wally]: https://wally.run

## Usage

To place features behind flags in your project, simply require the module and
access the flags you want to use and check if they're active. For example, to
use the `newHeroUpdate` flag we can request it asynchronously:

```lua
local FeatureFlags = require(ReplicatedStorage.Packages.FeatureFlags)

-- Asynchronously request our new hero feature flag.
FeatureFlags.get("newHeroUpdate"):andThen(function(flag: FeatureFlags.Flag)
  -- When the flag exists, check if it's active for the current user context.
  if flag.isActive({
    userId = Players.LocalPlayer.UserId,
    groups = { beta = isBetaTester(Players.LocalPlayer) },
  }) then
    -- The new hero is active for this user. Show off the new hero.
    displayNewHeroShowcase()
  else
    -- The new hero is not active for this user. Tease the hero that will be
    -- available soon.
    displayNewHeroTeaser()
  end
end)
```

Refer to the [API documentation][api] for more detailed information.

[api]: ../api/
