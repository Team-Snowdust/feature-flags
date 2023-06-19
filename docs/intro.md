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
FeatureFlags = "lasttalon/feature-flags@0.1.0"
```

[wally]: https://wally.run

## Usage

To use Feature Flags in your project, simply require the module and access the
hooks you want to use. For example, to use the `?` ?:

```lua
local FeatureFlags = require(ReplicatedStorage.Packages.MatterHooks)


```

Refer to the [API documentation][api] for a list of available hooks and their
parameters.

[api]: ../api/
