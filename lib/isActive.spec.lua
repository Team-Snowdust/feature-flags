local Package = script.Parent
local Flags = require(Package.Flags)
local isActive = require(Package.isActive)

return function()
	afterEach(function()
		Flags.reset()
	end)

	describe("exists", function()
		it("should error if the flag does not exist", function()
			expect(function()
				isActive("doesNotExist")
			end).to.throw("Flag 'doesNotExist' doesn't exist.")
		end)

		it("should not error if the flag exists", function()
			Flags.create("exists")
			expect(function()
				isActive("exists")
			end).to.never.throw()
		end)

		it("should not error if a default is provided", function()
			expect(function()
				isActive("doesNotExist", {}, { default = true })
			end).to.never.throw()
		end)

		it("should return the default when provided if the flag does not exist", function()
			local active = isActive("doesNotExist", {}, { default = true })
			expect(active).to.equal(true)
		end)

		it("should not error if `warnExists` is true", function()
			expect(function()
				isActive("doesNotExist", {}, { warnExists = true })
			end).to.never.throw()
		end)

		it("should return false if `warnExists` is true and no default is provided", function()
			local active = isActive("doesNotExist", {}, { warnExists = true })
			expect(active).to.equal(false)
		end)

		it("should return the default if `warnExists` is true and a default is provided", function()
			local active = isActive("doesNotExist", {}, { warnExists = true, default = true })
			expect(active).to.equal(true)
		end)
	end)

	describe("retired", function()
		beforeEach(function()
			Flags.create("retired", {
				retired = true,
			})
		end)

		it("should not error with default configuration", function()
			expect(function()
				isActive("retired")
			end).to.never.throw()
		end)

		it("should return true with default configuration", function()
			local active = isActive("retired")
			expect(active).to.equal(true)
		end)

		it("should not error with `warnRetire` set to false", function()
			expect(function()
				isActive("retired", {}, { warnRetire = false })
			end).to.never.throw()
		end)

		it("should return true with `warnRetire` set to false", function()
			local active = isActive("retired", {}, { warnRetire = false })
			expect(active).to.equal(true)
		end)

		it("should error with `allowRetire` set to false", function()
			expect(function()
				isActive("retired", {}, { allowRetire = false })
			end).to.throw("Flag 'retired' is retired.")
		end)
	end)

	describe("active", function()
		it("should be true when the flag is active", function()
			Flags.create("active", {
				active = true,
			})
			local active = isActive("active")
			expect(active).to.equal(true)
		end)

		it("should be false when the flag is not active", function()
			Flags.create("active", {
				active = false,
			})
			local active = isActive("active")
			expect(active).to.equal(false)
		end)
	end)

	describe("ruleSets", function()
		describe("active", function()
			it("should be false when the flag is not active regardless of rule sets", function()
				Flags.create("inactive", {
					active = false,
					ruleSets = {
						{
							allowedUsers = { [1] = true },
						},
					},
				})
				local active = isActive("inactive", { userId = 1 })
				expect(active).to.equal(false)
			end)
		end)

		describe("users", function()
			it("should be true when the user ID matches the allow list", function()
				Flags.create("users", {
					ruleSets = {
						{
							allowedUsers = { [1] = true },
						},
					},
				})
				local active = isActive("users", { userId = 1 })
				expect(active).to.equal(true)
			end)

			it("should be false when the user ID does not match the allow list", function()
				Flags.create("users", {
					ruleSets = {
						{
							allowedUsers = { [1] = true },
						},
					},
				})
				local active = isActive("users", { userId = 2 })
				expect(active).to.equal(false)
			end)

			it("should be false when the user ID matches the deny list", function()
				Flags.create("users", {
					ruleSets = {
						{
							forbiddenUsers = { [1] = true },
						},
					},
				})
				local active = isActive("users", { userId = 1 })
				expect(active).to.equal(false)
			end)

			it("should be true when the user ID does not match the deny list", function()
				Flags.create("users", {
					ruleSets = {
						{
							forbiddenUsers = { [1] = true },
						},
					},
				})
				local active = isActive("users", { userId = 2 })
				expect(active).to.equal(true)
			end)
		end)

		describe("groups", function()
			it("should be true when the group matches the allow list", function()
				Flags.create("groups", {
					ruleSets = {
						{
							allowedGroups = { group1 = true },
						},
					},
				})
				local active = isActive("groups", {
					groups = { group1 = true },
				})
				expect(active).to.equal(true)
			end)

			it("should be false when the group does not match the allow list", function()
				Flags.create("groups", {
					ruleSets = {
						{
							allowedGroups = { group1 = true },
						},
					},
				})
				local active = isActive("groups", {
					groups = { group2 = true },
				})
				expect(active).to.equal(false)
			end)

			it("should be false when the group matches the deny list", function()
				Flags.create("groups", {
					ruleSets = {
						{
							forbiddenGroups = { group1 = true },
						},
					},
				})
				local active = isActive("groups", {
					groups = { group1 = true },
				})
				expect(active).to.equal(false)
			end)

			it("should be true when the group does not match the deny list", function()
				Flags.create("groups", {
					ruleSets = {
						{
							forbiddenGroups = { group1 = true },
						},
					},
				})
				local active = isActive("groups", {
					groups = { group2 = true },
				})
				expect(active).to.equal(true)
			end)
		end)

		describe("system", function()
			it("should be true when the system state matches the allow list", function()
				Flags.create("system", {
					ruleSets = {
						{
							allowedSystemStates = { state1 = true },
						},
					},
				})
				local active = isActive("system", {
					systemStates = { state1 = true },
				})
				expect(active).to.equal(true)
			end)

			it("should be false when the system state does not match the allow list", function()
				Flags.create("system", {
					ruleSets = {
						{
							allowedSystemStates = { state1 = true },
						},
					},
				})
				local active = isActive("system", {
					systemStates = { state2 = true },
				})
				expect(active).to.equal(false)
			end)

			it("should be false when the system state matches the deny list", function()
				Flags.create("system", {
					ruleSets = {
						{
							forbiddenSystemStates = { state1 = true },
						},
					},
				})
				local active = isActive("system", {
					systemStates = { state1 = true },
				})
				expect(active).to.equal(false)
			end)

			it("should be true when the system state does not match the deny list", function()
				Flags.create("system", {
					ruleSets = {
						{
							forbiddenSystemStates = { state1 = true },
						},
					},
				})
				local active = isActive("system", {
					systemStates = { state2 = true },
				})
				expect(active).to.equal(true)
			end)
		end)

		describe("abSegments", function()
			it("should be true regardless of segments if there is no user id", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = true },
						},
					},
				})
				local active = isActive("abSegments")
				expect(active).to.equal(true)
			end)

			it("should be true when there is only one segment and it matches", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = 1 },
						},
					},
				})
				local active = isActive("abSegments", {
					userId = 1,
					abSegments = { segment1 = true },
				})
				expect(active).to.equal(true)
			end)

			it("should be false when there is only one segment and it does not match", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = 1 },
						},
					},
				})
				local active = isActive("abSegments", {
					userId = 1,
					abSegments = { segment2 = true },
				})
				expect(active).to.equal(false)
			end)

			it("should deterministically apportion users to segments", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = 1, segment2 = 1 },
						},
					},
				})

				-- A randomly generated seed for fuzz testing
				-- local RANGE = 2 ^ 31 - 1
				-- local seed = math.random(-RANGE, RANGE)
				-- print("Determinism fuzz seed:", seed)

				-- A pre-determined seed to ensure determinism
				local seed = -259204544

				local segment1Set = {}
				local segment2Set = {}
				local random = Random.new(seed)

				for _ = 1, 10000 do
					local userId = random:NextInteger(100000, 2 ^ 40)
					local active = isActive("abSegments", {
						userId = userId,
						abSegments = { segment1 = true },
					})
					if active then
						segment1Set[userId] = true
					else
						segment2Set[userId] = true
					end
				end

				for userId in segment1Set do
					local active = isActive("abSegments", {
						userId = userId,
						abSegments = { segment1 = true },
					})
					expect(active).to.equal(true)
				end

				for userId in segment2Set do
					local active = isActive("abSegments", {
						userId = userId,
						abSegments = { segment2 = true },
					})
					expect(active).to.equal(true)
				end
			end)

			it("should apportion users to segments based on the segment weights", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = 1, segment2 = 2 },
						},
					},
				})

				-- A randomly generated seed for fuzz testing
				-- local RANGE = 2 ^ 31 - 1
				-- local seed = math.random(-RANGE, RANGE)
				-- print("Proportion fuzz seed:", seed)

				-- A pre-determined seed to ensure determinism
				local seed = 1719500710

				local segment1Count = 0
				local segment2Count = 0
				local random = Random.new(seed)

				for _ = 1, 10000 do
					local userId = random:NextInteger(100000, 2 ^ 40)
					local active = isActive("abSegments", {
						userId = userId,
						abSegments = { segment1 = true },
					})
					if active then
						segment1Count += 1
					else
						segment2Count += 1
					end
				end

				expect(segment2Count).to.be.near(segment1Count * 2, 500)
			end)

			it("should be false when there are multiple segments and none match", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = 1, segment2 = 1 },
						},
					},
				})
				local active = isActive("abSegments", {
					userId = 1,
					abSegments = { segment3 = true },
				})
				expect(active).to.equal(false)
			end)

			it("should be true when there are multiple segments and one matches", function()
				Flags.create("abSegments", {
					ruleSets = {
						{
							abSegments = { segment1 = 1, segment2 = 1 },
						},
					},
				})
				local active = isActive("abSegments", {
					userId = 1,
					abSegments = { segment1 = true, segment2 = true },
				})
				expect(active).to.equal(true)
			end)
		end)

		describe("activation", function()
			it("should invoke the activation function", function()
				local activated = false
				Flags.create("activation", {
					ruleSets = {
						{
							activation = function()
								activated = true
							end,
						},
					},
				})

				expect(activated).to.equal(false)
				isActive("activation")
				expect(activated).to.equal(true)
			end)

			it("should pass the user context to the activation function", function()
				local originalContext = {}
				local matchedContext = false

				Flags.create("activation", {
					ruleSets = {
						{
							activation = function(passedContext)
								matchedContext = passedContext == originalContext
							end,
						},
					},
				})

				expect(matchedContext).to.equal(false)
				isActive("activation", originalContext)
				expect(matchedContext).to.equal(true)
			end)

			it("should pass the current rule set to the activation function", function()
				local matchedRuleSet = false
				local originalRuleSet

				originalRuleSet = {
					activation = function(_, passedRuleSet)
						matchedRuleSet = passedRuleSet == originalRuleSet
					end,
				}

				Flags.create("activation", {
					ruleSets = { originalRuleSet },
				})

				expect(matchedRuleSet).to.equal(false)
				isActive("activation")
				expect(matchedRuleSet).to.equal(true)
			end)

			it("should be true when the activation function returns true", function()
				Flags.create("activation", {
					ruleSets = {
						{
							activation = function()
								return true
							end,
						},
					},
				})

				local active = isActive("activation")
				expect(active).to.equal(true)
			end)

			it("should be false when the activation function returns false", function()
				Flags.create("activation", {
					ruleSets = {
						{
							activation = function()
								return false
							end,
						},
					},
				})

				local active = isActive("activation")
				expect(active).to.equal(false)
			end)

			it("should be true when the activation function returns nil", function()
				Flags.create("activation", {
					ruleSets = {
						{
							activation = function()
								return nil
							end,
						},
					},
				})

				local active = isActive("activation")
				expect(active).to.equal(true)
			end)
		end)
	end)
end
