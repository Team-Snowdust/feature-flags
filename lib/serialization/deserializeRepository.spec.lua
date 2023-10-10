local Serialization = script.Parent
local Package = Serialization.Parent
local Flags = require(Package.Flags)
local deserializeRepository = require(Serialization.deserializeRepository)

return function()
	afterEach(function()
		Flags.reset()
	end)

	it("should make no changes if the set of flags is empty", function()
		local repository = {
			["TestFlag"] = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}
		local flags = {}

		expect(Flags.exists("TestFlag")).to.equal(false)

		deserializeRepository(repository, flags)

		expect(Flags.exists("TestFlag")).to.equal(false)
	end)

	it("should create a flag if it does not exist", function()
		local repository = {
			["TestFlag"] = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}
		local flags = {
			["TestFlag"] = 1,
		}

		expect(Flags.exists("TestFlag")).to.equal(false)

		deserializeRepository(repository, flags)

		expect(Flags.exists("TestFlag")).to.equal(true)

		local flagConfig = Flags.read("TestFlag")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()
	end)

	it("should update a flag if it exists", function()
		local flag1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local flag2 = {
			config = {
				active = false,
				retired = true,
				ruleSets = {},
			},
			version = 2,
		}

		local repository1 = {
			["TestFlag"] = flag1,
		}
		local flags1 = {
			["TestFlag"] = 1,
		}

		expect(Flags.exists("TestFlag")).to.equal(false)

		deserializeRepository(repository1, flags1)

		expect(Flags.exists("TestFlag")).to.equal(true)

		local flagConfig = Flags.read("TestFlag")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		local repository2 = {
			["TestFlag"] = flag2,
		}

		local flags2 = {
			["TestFlag"] = 2,
		}

		deserializeRepository(repository2, flags2)

		expect(Flags.exists("TestFlag")).to.equal(true)

		flagConfig = Flags.read("TestFlag")
		expect(flagConfig.active).to.equal(false)
		expect(flagConfig.retired).to.equal(true)
		expect(flagConfig.ruleSets).to.be.ok()
	end)

	it("should error if the flag does not exist in the repository", function()
		local repository = {}
		local flags = {
			["TestFlag"] = 1,
		}

		expect(function()
			deserializeRepository(repository, flags)
		end).to.throw("Flag 'TestFlag' not found in repository.")
	end)

	it("should create many new flags if they do not exist", function()
		local repository = {
			["TestFlag1"] = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
			["TestFlag2"] = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
			["TestFlag3"] = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}
		local flags = {
			["TestFlag1"] = 1,
			["TestFlag2"] = 1,
			["TestFlag3"] = 1,
		}

		expect(Flags.exists("TestFlag1")).to.equal(false)
		expect(Flags.exists("TestFlag2")).to.equal(false)
		expect(Flags.exists("TestFlag3")).to.equal(false)

		deserializeRepository(repository, flags)

		expect(Flags.exists("TestFlag1")).to.equal(true)
		expect(Flags.exists("TestFlag2")).to.equal(true)
		expect(Flags.exists("TestFlag3")).to.equal(true)

		local flagConfig = Flags.read("TestFlag1")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag2")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag3")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()
	end)

	it("should update many flags if they exist", function()
		local flag1v1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local flag1v2 = {
			config = {
				active = false,
				retired = true,
				ruleSets = {},
			},
			version = 2,
		}

		local flag2v1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local flag2v2 = {
			config = {
				active = false,
				retired = true,
				ruleSets = {},
			},
			version = 2,
		}

		local flag3v1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local flag3v2 = {
			config = {
				active = false,
				retired = true,
				ruleSets = {},
			},
			version = 2,
		}

		local repository1 = {
			["TestFlag1"] = flag1v1,
			["TestFlag2"] = flag2v1,
			["TestFlag3"] = flag3v1,
		}
		local flags1 = {
			["TestFlag1"] = 1,
			["TestFlag2"] = 1,
			["TestFlag3"] = 1,
		}

		expect(Flags.exists("TestFlag1")).to.equal(false)
		expect(Flags.exists("TestFlag2")).to.equal(false)
		expect(Flags.exists("TestFlag3")).to.equal(false)

		deserializeRepository(repository1, flags1)

		expect(Flags.exists("TestFlag1")).to.equal(true)
		expect(Flags.exists("TestFlag2")).to.equal(true)
		expect(Flags.exists("TestFlag3")).to.equal(true)

		local flagConfig = Flags.read("TestFlag1")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag2")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag3")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		local repository2 = {
			["TestFlag1"] = flag1v2,
			["TestFlag2"] = flag2v2,
			["TestFlag3"] = flag3v2,
		}

		local flags2 = {
			["TestFlag1"] = 2,
			["TestFlag2"] = 2,
			["TestFlag3"] = 2,
		}

		deserializeRepository(repository2, flags2)

		expect(Flags.exists("TestFlag1")).to.equal(true)
		expect(Flags.exists("TestFlag2")).to.equal(true)
		expect(Flags.exists("TestFlag3")).to.equal(true)

		flagConfig = Flags.read("TestFlag1")
		expect(flagConfig.active).to.equal(false)
		expect(flagConfig.retired).to.equal(true)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag2")
		expect(flagConfig.active).to.equal(false)
		expect(flagConfig.retired).to.equal(true)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag3")
		expect(flagConfig.active).to.equal(false)
		expect(flagConfig.retired).to.equal(true)
		expect(flagConfig.ruleSets).to.be.ok()
	end)

	it("should update flags and create new flags at the same time", function()
		local flag1v1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local flag1v2 = {
			config = {
				active = false,
				retired = true,
				ruleSets = {},
			},
			version = 2,
		}

		local flag2v1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local flag2v2 = {
			config = {
				active = false,
				retired = true,
				ruleSets = {},
			},
			version = 2,
		}

		local flag3v1 = {
			config = {
				active = true,
				retired = false,
				ruleSets = {},
			},
			version = 1,
		}

		local repository1 = {
			["TestFlag1"] = flag1v1,
			["TestFlag2"] = flag2v1,
		}
		local flags1 = {
			["TestFlag1"] = 1,
			["TestFlag2"] = 1,
		}

		expect(Flags.exists("TestFlag1")).to.equal(false)
		expect(Flags.exists("TestFlag2")).to.equal(false)
		expect(Flags.exists("TestFlag3")).to.equal(false)

		deserializeRepository(repository1, flags1)

		expect(Flags.exists("TestFlag1")).to.equal(true)
		expect(Flags.exists("TestFlag2")).to.equal(true)
		expect(Flags.exists("TestFlag3")).to.equal(false)

		local flagConfig = Flags.read("TestFlag1")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag2")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()

		local repository2 = {
			["TestFlag1"] = flag1v2,
			["TestFlag2"] = flag2v2,
			["TestFlag3"] = flag3v1,
		}

		local flags2 = {
			["TestFlag1"] = 2,
			["TestFlag2"] = 2,
			["TestFlag3"] = 1,
		}

		deserializeRepository(repository2, flags2)

		expect(Flags.exists("TestFlag1")).to.equal(true)
		expect(Flags.exists("TestFlag2")).to.equal(true)
		expect(Flags.exists("TestFlag3")).to.equal(true)

		flagConfig = Flags.read("TestFlag1")
		expect(flagConfig.active).to.equal(false)
		expect(flagConfig.retired).to.equal(true)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag2")
		expect(flagConfig.active).to.equal(false)
		expect(flagConfig.retired).to.equal(true)
		expect(flagConfig.ruleSets).to.be.ok()

		flagConfig = Flags.read("TestFlag3")
		expect(flagConfig.active).to.equal(true)
		expect(flagConfig.retired).to.equal(false)
		expect(flagConfig.ruleSets).to.be.ok()
	end)
end
