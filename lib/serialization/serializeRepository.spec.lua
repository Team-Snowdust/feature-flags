local serializeRepository = require(script.Parent.serializeRepository)

return function()
	FOCUS()

	it("should not make any changes to an empty repository when given no changes", function()
		local repository = {}

		local updatedRepository = serializeRepository(repository, {})

		expect((next(updatedRepository))).to.equal(nil)
	end)

	it("should not make any changes when given no changes", function()
		local repository = {
			flag1 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
			flag2 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}

		local updatedRepository = serializeRepository(repository, {})

		expect(updatedRepository.flag1).to.be.ok()
		expect(updatedRepository.flag1.version).to.equal(1)

		expect(updatedRepository.flag2).to.be.ok()
		expect(updatedRepository.flag2.version).to.equal(1)
	end)

	it("should add a new flag to a repository", function()
		local repository = {
			flag1 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
			flag2 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}

		local updatedRepository = serializeRepository(repository, {
			flag3 = {
				change = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		})

		expect(updatedRepository.flag1).to.be.ok()
		expect(updatedRepository.flag1.version).to.equal(1)

		expect(updatedRepository.flag2).to.be.ok()
		expect(updatedRepository.flag2.version).to.equal(1)

		expect(updatedRepository.flag3).to.be.ok()
		expect(updatedRepository.flag2.version).to.equal(1)
	end)

	it("should update an existing flag in a repository", function()
		local repository = {
			flag1 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
			flag2 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}

		local updatedRepository = serializeRepository(repository, {
			flag1 = {
				change = {
					active = false,
					retired = true,
					ruleSets = {},
				},
				version = 2,
			},
		})

		expect(updatedRepository.flag1).to.be.ok()
		expect(updatedRepository.flag1.version).to.equal(2)
		expect(updatedRepository.flag1.config.active).to.equal(false)
		expect(updatedRepository.flag1.config.retired).to.equal(true)

		expect(updatedRepository.flag2).to.be.ok()
		expect(updatedRepository.flag2.version).to.equal(1)
	end)

	it("should remove an existing flag from a repository", function()
		local repository = {
			flag1 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
			flag2 = {
				config = {
					active = true,
					retired = false,
					ruleSets = {},
				},
				version = 1,
			},
		}

		local updatedRepository = serializeRepository(repository, {
			flag1 = {
				version = 2,
			},
		})

		expect(updatedRepository.flag1).to.be.ok()
		expect(updatedRepository.flag1.config).never.to.be.ok()
		expect(updatedRepository.flag1.version).to.equal(2)

		expect(updatedRepository.flag2).to.be.ok()
		expect(updatedRepository.flag2.version).to.equal(1)
	end)
end
