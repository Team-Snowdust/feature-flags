local serializeFlagsToDirectory = require(script.Parent.serializeFlagsToDirectory)

return function()
	describe("Changes", function()
		it("should make no changes when there are no flag changes", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local _, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {})

			expect((next(managedChanges))).never.to.be.ok()
			expect((next(userChanges))).never.to.be.ok()
		end)

		it("should make changes when updating a flag", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local _, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag2 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag2).to.be.ok()
		end)

		it("should make many changes when updating many flags", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local _, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag1 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag2 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag3 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag1).to.be.ok()
			expect(managedChanges["0"].flag2).to.be.ok()
			expect(managedChanges["0"].flag3).to.be.ok()
		end)

		it("should make changes to the appropriate repositories", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "2",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "3",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "2",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "3",
					version = 1,
				},
			}

			local _, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag1 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag2 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag3 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag1).to.be.ok()
			expect(managedChanges["2"]).to.be.ok()
			expect(managedChanges["2"].flag2).to.be.ok()
			expect(managedChanges["3"]).to.be.ok()
			expect(managedChanges["3"].flag3).to.be.ok()
		end)

		it("should make changes to the appropriate repositories when the cache differs", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "2",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "3",
					version = 1,
				},
			}

			local _, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag1 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag2 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag3 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag1).to.be.ok()
			expect(managedChanges["2"]).to.be.ok()
			expect(managedChanges["2"].flag2).to.be.ok()
			expect(managedChanges["3"]).to.be.ok()
			expect(managedChanges["3"].flag3).to.be.ok()
		end)

		it("should provide change versions", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 3,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 3,
				},
			}

			local _, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag1 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag2 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
					flag3 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag1).to.be.ok()
			expect(managedChanges["0"].flag1.version).to.equal(2)
			expect(managedChanges["0"].flag2).to.be.ok()
			expect(managedChanges["0"].flag2.version).to.equal(3)
			expect(managedChanges["0"].flag3).to.be.ok()
			expect(managedChanges["0"].flag3.version).to.equal(4)
		end)
	end)

	describe("Directory", function()
		it("should return the new directory for convenience", function()
			local oldDirectory = {}
			local newDirectory = {}

			local updatedDirectory = serializeFlagsToDirectory(oldDirectory, newDirectory, {})

			expect(updatedDirectory).to.equal(newDirectory)
		end)

		it("should make no changes to an empty directory when provided no changes", function()
			local oldDirectory = {}
			local newDirectory = {}

			local updatedDirectory = serializeFlagsToDirectory(oldDirectory, newDirectory, {})

			expect((next(updatedDirectory))).never.to.be.ok()
		end)

		it("should make no changes to a directory when provided no changes", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local updatedDirectory = serializeFlagsToDirectory(oldDirectory, newDirectory, {})

			expect(updatedDirectory).to.be.ok()
			expect(updatedDirectory.flag1).to.be.ok()
			expect(updatedDirectory.flag1.version).to.be.ok()
			expect(updatedDirectory.flag2).to.be.ok()
			expect(updatedDirectory.flag2.version).to.be.ok()
			expect(updatedDirectory.flag3).to.be.ok()
			expect(updatedDirectory.flag3.version).to.be.ok()
		end)

		it("should provide the correct versions", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 3,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 3,
				},
			}

			local updatedDirectory = serializeFlagsToDirectory(oldDirectory, newDirectory, {})

			expect(updatedDirectory).to.be.ok()
			expect(updatedDirectory.flag1).to.be.ok()
			expect(updatedDirectory.flag1.version).to.equal(1)
			expect(updatedDirectory.flag2).to.be.ok()
			expect(updatedDirectory.flag2.version).to.equal(2)
			expect(updatedDirectory.flag3).to.be.ok()
			expect(updatedDirectory.flag3.version).to.equal(3)
		end)

		it("should provide the new directory if the cached flag is old", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local updatedDirectory = serializeFlagsToDirectory(oldDirectory, newDirectory, {
				flag1 = {
					change = {
						active = true,
						retired = false,
						ruleSets = {},
					},
				},
			})

			expect(updatedDirectory).to.be.ok()
			expect(updatedDirectory.flag1).to.be.ok()
			expect(updatedDirectory.flag1.version).to.equal(2)
		end)

		it("should update the old directory if the new directory is more recent", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			serializeFlagsToDirectory(oldDirectory, newDirectory, {
				flag1 = {
					change = {
						active = true,
						retired = false,
						ruleSets = {},
					},
				},
			})

			expect(oldDirectory.flag1).to.be.ok()
			expect(oldDirectory.flag1.version).to.equal(2)
		end)

		it("should update the new directory if the old directory is more recent", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			serializeFlagsToDirectory(oldDirectory, newDirectory, {
				flag1 = {
					change = {
						active = true,
						retired = false,
						ruleSets = {},
					},
				},
			})

			expect(newDirectory.flag1).to.be.ok()
			expect(newDirectory.flag1.version).to.equal(3)
		end)

		it("should not update entries that are not changing", function()
			local oldDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 2,
				},
			}

			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
				flag2 = {
					managed = true,
					repository = "0",
					version = 2,
				},
				flag3 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			serializeFlagsToDirectory(oldDirectory, newDirectory, {
				flag1 = {
					change = {
						active = true,
						retired = false,
						ruleSets = {},
					},
				},
			})

			expect(oldDirectory.flag2).to.be.ok()
			expect(oldDirectory.flag2.version).to.equal(1)
			expect(newDirectory.flag3).to.be.ok()
			expect(newDirectory.flag3.version).to.equal(1)
		end)
	end)

	describe("New Entries", function()
		it("should create new entries when they do not exist", function()
			local oldDirectory = {}
			local newDirectory = {}

			local updatedDirectory, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag1 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag1).to.be.ok()
			expect(managedChanges["0"].flag1.version).to.equal(0)

			expect(updatedDirectory).to.be.ok()
			expect(updatedDirectory.flag1).to.be.ok()
			expect(updatedDirectory.flag1.version).to.equal(0)
		end)

		it("should create new entries when they do not exist and the cache is old", function()
			local oldDirectory = {}
			local newDirectory = {
				flag1 = {
					managed = true,
					repository = "0",
					version = 1,
				},
			}

			local updatedDirectory, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag2 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["0"]).to.be.ok()
			expect(managedChanges["0"].flag2).to.be.ok()
			expect(managedChanges["0"].flag2.version).to.equal(0)

			expect(updatedDirectory).to.be.ok()
			expect(updatedDirectory.flag2).to.be.ok()
			expect(updatedDirectory.flag2.version).to.equal(0)
		end)

		it(
			"should create new entries when they do not exist and the cache contains them",
			function()
				local oldDirectory = {
					flag1 = {
						managed = true,
						repository = "0",
						version = 1,
					},
				}

				local newDirectory = {}

				local updatedDirectory, managedChanges, userChanges =
					serializeFlagsToDirectory(oldDirectory, newDirectory, {
						flag1 = {
							change = {
								active = true,
								retired = false,
								ruleSets = {},
							},
						},
					})

				expect((next(userChanges))).never.to.be.ok()

				expect(managedChanges["0"]).to.be.ok()
				expect(managedChanges["0"].flag1).to.be.ok()
				expect(managedChanges["0"].flag1.version).to.equal(2)

				expect(updatedDirectory).to.be.ok()
				expect(updatedDirectory.flag1).to.be.ok()
				expect(updatedDirectory.flag1.version).to.equal(2)
			end
		)

		it(
			"should place new entries into a repository if it contains fewer than 1024 flags",
			function()
				local oldDirectory = {}
				local newDirectory = {}

				for i = 1, 1023 do
					newDirectory["flag" .. i] = {
						managed = true,
						repository = "0",
						version = 1,
					}
				end

				local updatedDirectory, managedChanges, userChanges =
					serializeFlagsToDirectory(oldDirectory, newDirectory, {
						flag1024 = {
							change = {
								active = true,
								retired = false,
								ruleSets = {},
							},
						},
					})

				expect((next(userChanges))).never.to.be.ok()

				expect(managedChanges["0"]).to.be.ok()
				expect(managedChanges["0"].flag1024).to.be.ok()
				expect(managedChanges["0"].flag1024.version).to.equal(0)

				expect(updatedDirectory).to.be.ok()
				expect(updatedDirectory.flag1024).to.be.ok()
				expect(updatedDirectory.flag1024.version).to.equal(0)
			end
		)

		it(
			"should place new entries into a new repository if it contains 1024 flags or more",
			function()
				local oldDirectory = {}
				local newDirectory = {}

				for i = 1, 1024 do
					newDirectory["flag" .. i] = {
						managed = true,
						repository = "0",
						version = 1,
					}
				end

				local updatedDirectory, managedChanges, userChanges =
					serializeFlagsToDirectory(oldDirectory, newDirectory, {
						flag1025 = {
							change = {
								active = true,
								retired = false,
								ruleSets = {},
							},
						},
					})

				expect((next(userChanges))).never.to.be.ok()

				expect(managedChanges["1"]).to.be.ok()
				expect(managedChanges["1"].flag1025).to.be.ok()
				expect(managedChanges["1"].flag1025.version).to.equal(0)

				expect(updatedDirectory).to.be.ok()
				expect(updatedDirectory.flag1025).to.be.ok()
				expect(updatedDirectory.flag1025.version).to.equal(0)
			end
		)

		it("should place new entries into a the first repository with room", function()
			local oldDirectory = {}
			local newDirectory = {}

			local REPO_0_COUNT = 1024
			local REPO_1_COUNT = 1023
			local REPO_2_COUNT = 1024

			for i = 1, REPO_0_COUNT do
				newDirectory["flag" .. i] = {
					managed = true,
					repository = "0",
					version = 1,
				}
			end

			for i = 1, REPO_1_COUNT do
				newDirectory["flag" .. i + REPO_0_COUNT] = {
					managed = true,
					repository = "1",
					version = 1,
				}
			end

			for i = 1, REPO_2_COUNT do
				newDirectory["flag" .. i + REPO_0_COUNT + REPO_1_COUNT] = {
					managed = true,
					repository = "2",
					version = 1,
				}
			end

			local updatedDirectory, managedChanges, userChanges =
				serializeFlagsToDirectory(oldDirectory, newDirectory, {
					flag3072 = {
						change = {
							active = true,
							retired = false,
							ruleSets = {},
						},
					},
				})

			expect((next(userChanges))).never.to.be.ok()

			expect(managedChanges["1"]).to.be.ok()
			expect(managedChanges["1"].flag3072).to.be.ok()
			expect(managedChanges["1"].flag3072.version).to.equal(0)

			expect(updatedDirectory).to.be.ok()
			expect(updatedDirectory.flag3072).to.be.ok()
			expect(updatedDirectory.flag3072.version).to.equal(0)
		end)
	end)
end
