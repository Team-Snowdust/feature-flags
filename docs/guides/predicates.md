---
sidebar_position: 2
---

# Preferring Predicates

When using feature flags, developers often face the choice between using
activation functions or leveraging predicates within user groups or system
states. While both can be effective in certain scenarios, predicates should be
preferred in most situations, offering more clarity, control, and consistency.

## Difference Between Activation Functions and Predicates

**Activation Functions**:

- Determine whether a feature flag should be active.
- Their dynamic nature makes them flexible and powerful.
- The flexibility comes at the cost of serialization. Activation functions
  cannot be serialized, and need to be handled separately which can lead to
  unexpected behaviors.

**Predicates**:

- Are conditions that determines the truth value for a specific scenario, e.g.
  `isInBetaGroup()`.
- When used within user groups or system states, they can provide a clear,
  concise, and consistent method to control feature activation.
- As they're based on predefined conditions and don't require function
  execution, they're inherently serializable.

They differ in usage as well. Activation functions are set during flag
configuration, while predicates are used to define the conditions under which a
flag is active.

```lua title="Activation Function"
FeatureFlags.create("myFlag", {
	active = true,
	ruleSets = {
		{
			activation = function()
				-- Determine if the feature should be active
			end,
		},
	},
})
```

```lua title="Predicate"
if
	FeatureFlags.isActive("myFlag", {
		userId = userId,
		groups = {
			-- We check if the user is in the beta group with this predicate
			beta = isInBetaGroup(userId),
		},
	})
then
	-- This flag is active for this user
end
```

## Benefits of Predicates

1. **Explicit Handling**: With predicates, developers have more explicit control
   over the conditions under which a feature is activated. Since the logic is
   laid out clearly, it's easier for other team members to understand, debug,
   and maintain. There is no magic function hidden in the background that
   determines if a flag is active or not.
2. **Side Effects**: Activation functions can have side effects, which might
   lead to unpredictable behavior, especially if external dependencies change.
   Predicates, on the other hand, are pure and deterministic, providing a safer
   way to manage features.
3. **Clarity**: Predicates are more readable and easier to understand than
   activation functions. They can be used to define conditions based on user
   groups, system states, or any other predefined condition.
4. **Consistency**: Predicates provide simple booleans which are inherently
   serializable, making them easier to use and share across different systems.
5. **Scalability**: As your system grows and you have more feature flags to
   manage, keeping track of various activation functions can become cumbersome.
   Predicates, being more declarative, make it simpler to scale your feature
   management without getting lost in the intricacies of function behaviors.

## When to Use Activation Functions

That said, activation functions have their place. They can be beneficial when:

- You need to compute dynamic data that cannot be determined by a simple
  condition.
- You have a complex set of rules that can't be easily encapsulated within a
  predicate.
- You're working in a tightly controlled environment where serialization is not
  a concern.

## Conclusion

While activation functions offer flexibility, predicates within user groups or
system states provide a more transparent, controlled, and scalable method for
feature flag management. By favoring predicates, developers can ensure that
their features are always handled as intended, reducing potential issues down
the line.

Activation functions are included for times when you need the additional
flexibility or power they provide. However, they should be used sparingly and
with caution. Predicates can do much of the same work, while providing a more
consistent and predictable experience.
