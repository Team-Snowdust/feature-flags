local Package = script.Parent
local Flags = require(Package.Flags)
local createFlag = require(Package.createFlag)

return function()
	afterEach(function()
		Flags.reset()
	end)

	describe("createFlag", function()
		it("should create a flag object", function()
			local flag = createFlag("flag")
			expect(flag).to.be.ok()
			expect(flag.name).to.be.a("string")
			expect(flag.create).to.be.a("function")
			expect(flag.exists).to.be.a("function")
			expect(flag.read).to.be.a("function")
			expect(flag.update).to.be.a("function")
			expect(flag.retire).to.be.a("function")
			expect(flag.destroy).to.be.a("function")
			expect(flag.isActive).to.be.a("function")
			expect(flag.onChange).to.be.a("function")
		end)

		it("should create a flag with the correct name", function()
			local flag = createFlag("flag")
			expect(flag.name).to.equal("flag")
		end)
	end)

	describe("create", function()
		it("should not exist unless created", function()
			createFlag("flag")
			expect(Flags.exists("flag")).to.equal(false)
		end)

		it("should create a flag", function()
			local flag = createFlag("flag")
			expect(Flags.exists("flag")).to.equal(false)

			flag.create()
			expect(Flags.exists("flag")).to.equal(true)
		end)

		it("should error if the flag already exists", function()
			local flag = createFlag("flag")
			flag.create()
			expect(function()
				flag.create()
			end).to.throw("Flag 'flag' already exists.")
		end)
	end)

	describe("exists", function()
		it("should return false if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(flag.exists()).to.equal(false)
		end)

		it("should return true if the flag exists", function()
			local flag = createFlag("flag")
			expect(flag.exists()).to.equal(false)
			flag.create()
			expect(flag.exists()).to.equal(true)
		end)

		it("should agree with Flags", function()
			local flag = createFlag("flag")
			expect(Flags.exists("flag")).to.equal(false)
			flag.create()
			expect(Flags.exists("flag")).to.equal(true)
		end)
	end)

	describe("read", function()
		it("should error if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(function()
				flag.read()
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should return the flag data if it exists", function()
			local flag = createFlag("flag")
			flag.create()
			local flagConfig = flag.read()
			expect(flagConfig).to.be.ok()
			expect(flagConfig.active).to.equal(true)
			expect(flagConfig.retired).to.equal(false)
			expect(flagConfig.ruleSets).to.be.ok()
		end)

		it("should agree with Flags", function()
			local flag = createFlag("flag")
			flag.create()
			expect(flag.read()).to.equal(Flags.read("flag"))
		end)
	end)

	describe("update", function()
		it("should error if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(function()
				flag.update({ active = true })
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should update the flag data", function()
			local flag = createFlag("flag")
			flag.create()
			expect(flag.read().active).to.equal(true)

			flag.update({ active = false })
			expect(flag.read().active).to.equal(false)
		end)
	end)

	describe("retire", function()
		it("should error if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(function()
				flag.retire()
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should retire the flag", function()
			local flag = createFlag("flag")
			flag.create()
			expect(flag.read().retired).to.equal(false)

			flag.retire()
			expect(flag.read().retired).to.equal(true)
		end)

		it("should un-retire the flag", function()
			local flag = createFlag("flag")
			flag.create({ retired = true })
			expect(flag.read().retired).to.equal(true)

			flag.retire(false)
			expect(flag.read().retired).to.equal(false)
		end)
	end)

	describe("destroy", function()
		it("should error if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(function()
				flag.destroy()
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should destroy the flag", function()
			local flag = createFlag("flag")
			flag.create()
			expect(flag.exists()).to.equal(true)

			flag.destroy()
			expect(flag.exists()).to.equal(false)
		end)
	end)

	describe("isActive", function()
		it("should error if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(function()
				flag.isActive()
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should return true if the flag is active", function()
			local flag = createFlag("flag")
			flag.create()
			expect(flag.isActive()).to.equal(true)
		end)

		it("should return false if the flag is not active", function()
			local flag = createFlag("flag")
			flag.create({ active = false })
			expect(flag.isActive()).to.equal(false)
		end)

		it("should return true if the flag is retired", function()
			local flag = createFlag("flag")
			flag.create({ retired = true })
			expect(flag.isActive()).to.equal(true)
		end)

		it("should apply the given configuration", function()
			local flag = createFlag("flag")
			expect(function()
				flag.isActive({}, { default = true })
			end).never.to.throw()
		end)

		it("should apply the given context", function()
			local flag = createFlag("flag")
			flag.create({
				ruleSets = {
					{ allowedUsers = { [1] = true } },
				},
			})
			expect(flag.isActive({ userId = 1 })).to.equal(true)
			expect(flag.isActive({ userId = 2 })).to.equal(false)
		end)
	end)

	describe("onChange", function()
		local connection

		afterEach(function()
			if connection then
				connection.disconnect()
			end
		end)

		it("should not error if the flag does not exist", function()
			local flag = createFlag("flag")
			expect(function()
				connection = flag.onChange(function() end)
			end).never.to.throw()
		end)

		it("should call the callback when the flag is created", function()
			local flag = createFlag("flag")

			local called = false
			connection = flag.onChange(function()
				called = true
			end)

			expect(called).to.equal(false)
			flag.create()
			expect(called).to.equal(true)
		end)

		it("should call the callback when the flag is updated", function()
			local flag = createFlag("flag")
			flag.create()

			local called = false
			connection = flag.onChange(function()
				called = true
			end)

			expect(called).to.equal(false)
			flag.update({ active = false })
			expect(called).to.equal(true)
		end)

		it("should not call the callback when a different flag is updated", function()
			local flag1 = createFlag("flag1")
			local flag2 = createFlag("flag2")
			flag1.create()
			flag2.create()

			local called = false
			connection = flag1.onChange(function()
				called = true
			end)

			expect(called).to.equal(false)
			flag2.update({ active = false })
			expect(called).to.equal(false)
		end)

		it("should provide a change record", function()
			local flag = createFlag("flag")
			flag.create()

			local changeRecord
			connection = flag.onChange(function(record: Flags.ChangeRecord)
				changeRecord = record
			end)

			expect(changeRecord).never.to.be.ok()
			flag.update({ active = false })
			expect(changeRecord).to.be.ok()
		end)

		it("should provide the update options", function()
			local flag = createFlag("flag")
			flag.create()

			local updateOptions
			connection = flag.onChange(function(_, options: Flags.UpdateOptions)
				updateOptions = options
			end)

			expect(updateOptions).never.to.be.ok()
			flag.update({ active = false })
			expect(updateOptions).to.be.ok()
		end)
	end)
end
