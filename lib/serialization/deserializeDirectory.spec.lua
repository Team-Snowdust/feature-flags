local deserializeDirectory = require(script.Parent.deserializeDirectory)

return function()
	describe("Unchanged", function()
		it("should return an empty set of updates when given two empty directories", function()
			local updates = deserializeDirectory({}, {})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.managed))).to.equal(nil)
			expect((next(updates.user))).to.equal(nil)
			expect((next(updates.removed))).to.equal(nil)
		end)

		it("should return an empty set of updates when given two identical directories", function()
			local updates = deserializeDirectory({
				["flag"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			}, {
				["flag"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.managed))).to.equal(nil)
			expect((next(updates.user))).to.equal(nil)
			expect((next(updates.removed))).to.equal(nil)
		end)

		it(
			"should return an empty set of updates when given two identical directories with many flags",
			function()
				local updates = deserializeDirectory({
					["flag1"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag2"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag3"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag4"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag5"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
				}, {
					["flag1"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag2"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag3"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag4"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag5"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
				})

				expect(updates).to.be.a("table")
				expect(updates.managed).to.be.a("table")
				expect(updates.user).to.be.a("table")
				expect(updates.removed).to.be.a("table")

				expect((next(updates.managed))).to.equal(nil)
				expect((next(updates.user))).to.equal(nil)
				expect((next(updates.removed))).to.equal(nil)
			end
		)
	end)

	describe("Removal", function()
		it("should return a set of removals when given a directory with a flag removed", function()
			local updates = deserializeDirectory({
				["flag"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			}, {})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.managed))).to.equal(nil)
			expect((next(updates.user))).to.equal(nil)

			expect(updates.removed["flag"]).to.equal(true)
		end)

		it(
			"should return a set of removals when given a directory with many flags removed",
			function()
				local updates = deserializeDirectory({
					["flag1"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag2"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag3"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag4"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag5"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
				}, {
					["flag1"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag2"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
				})

				expect(updates).to.be.a("table")
				expect(updates.managed).to.be.a("table")
				expect(updates.user).to.be.a("table")
				expect(updates.removed).to.be.a("table")

				expect((next(updates.managed))).to.equal(nil)
				expect((next(updates.user))).to.equal(nil)

				expect(updates.removed["flag3"]).to.equal(true)
				expect(updates.removed["flag4"]).to.equal(true)
				expect(updates.removed["flag5"]).to.equal(true)
			end
		)

		it("should return a set of removals when some flags have changed", function()
			local updates = deserializeDirectory({
				["flag1"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag2"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag3"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag4"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag5"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			}, {
				["flag1"] = {
					managed = true,
					repository = "TestRepository",
					version = 2,
				},
				["flag2"] = {
					managed = true,
					repository = "TestRepository",
					version = 2,
				},
			})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.managed))).to.ok()
			expect((next(updates.user))).to.equal(nil)

			expect(updates.removed["flag3"]).to.equal(true)
			expect(updates.removed["flag4"]).to.equal(true)
			expect(updates.removed["flag5"]).to.equal(true)
		end)
	end)

	describe("Updates", function()
		it("should return a set of updates when given a directory with a flag added", function()
			local updates = deserializeDirectory({}, {
				["flag"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.user))).to.equal(nil)
			expect((next(updates.removed))).to.equal(nil)

			expect(updates.managed["TestRepository"]).to.be.a("table")
			expect(updates.managed["TestRepository"]["flag"]).to.equal(1)
		end)

		it("should return a set of updates when given a directory with many flags added", function()
			local updates = deserializeDirectory({}, {
				["flag1"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag2"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag3"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag4"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag5"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.user))).to.equal(nil)
			expect((next(updates.removed))).to.equal(nil)

			expect(updates.managed["TestRepository"]).to.be.a("table")
			expect(updates.managed["TestRepository"]["flag1"]).to.equal(1)
			expect(updates.managed["TestRepository"]["flag2"]).to.equal(1)
			expect(updates.managed["TestRepository"]["flag3"]).to.equal(1)
			expect(updates.managed["TestRepository"]["flag4"]).to.equal(1)
			expect(updates.managed["TestRepository"]["flag5"]).to.equal(1)
		end)

		it("should return a set of updates when given a directory with a flag changed", function()
			local updates = deserializeDirectory({
				["flag"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			}, {
				["flag"] = {
					managed = true,
					repository = "TestRepository",
					version = 2,
				},
			})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.user))).to.equal(nil)
			expect((next(updates.removed))).to.equal(nil)

			expect(updates.managed["TestRepository"]).to.be.a("table")
			expect(updates.managed["TestRepository"]["flag"]).to.equal(2)
		end)

		it(
			"should return a set of updates when a given a directory with many flags changed",
			function()
				local updates = deserializeDirectory({
					["flag1"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag2"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag3"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag4"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag5"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
				}, {
					["flag1"] = {
						managed = true,
						repository = "TestRepository",
						version = 2,
					},
					["flag2"] = {
						managed = true,
						repository = "TestRepository",
						version = 2,
					},
					["flag3"] = {
						managed = true,
						repository = "TestRepository",
						version = 2,
					},
					["flag4"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
					["flag5"] = {
						managed = true,
						repository = "TestRepository",
						version = 1,
					},
				})

				expect(updates).to.be.a("table")
				expect(updates.managed).to.be.a("table")
				expect(updates.user).to.be.a("table")
				expect(updates.removed).to.be.a("table")

				expect((next(updates.user))).to.equal(nil)
				expect((next(updates.removed))).to.equal(nil)

				expect(updates.managed["TestRepository"]).to.be.a("table")
				expect(updates.managed["TestRepository"]["flag1"]).to.equal(2)
				expect(updates.managed["TestRepository"]["flag2"]).to.equal(2)
				expect(updates.managed["TestRepository"]["flag3"]).to.equal(2)
			end
		)

		it("should return a set of updates when flags are removed", function()
			local updates = deserializeDirectory({
				["flag1"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag2"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag3"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag4"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
				["flag5"] = {
					managed = true,
					repository = "TestRepository",
					version = 1,
				},
			}, {
				["flag1"] = {
					managed = true,
					repository = "TestRepository",
					version = 2,
				},
				["flag2"] = {
					managed = true,
					repository = "TestRepository",
					version = 2,
				},
			})

			expect(updates).to.be.a("table")
			expect(updates.managed).to.be.a("table")
			expect(updates.user).to.be.a("table")
			expect(updates.removed).to.be.a("table")

			expect((next(updates.user))).to.equal(nil)
			expect((next(updates.removed))).to.ok()

			expect(updates.managed["TestRepository"]).to.be.a("table")
			expect(updates.managed["TestRepository"]["flag1"]).to.equal(2)
			expect(updates.managed["TestRepository"]["flag2"]).to.equal(2)
		end)
	end)
end
