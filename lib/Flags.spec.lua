local Flags = require(script.Parent.Flags)

return function()
	afterEach(function()
		Flags.reset()
	end)

	describe("create", function()
		it("should not exist unless created", function()
			expect(Flags.exists("flag")).to.equal(false)
		end)

		it("should create a flag", function()
			expect(Flags.exists("flag")).to.equal(false)

			Flags.create("flag")
			expect(Flags.exists("flag")).to.equal(true)
		end)

		it("should error if the flag already exists", function()
			Flags.create("flag")
			expect(function()
				Flags.create("flag")
			end).to.throw("Flag 'flag' already exists.")
		end)
	end)

	describe("exists", function()
		it("should return false if the flag does not exist", function()
			expect(Flags.exists("flag")).to.equal(false)
		end)

		it("should return true if the flag exists", function()
			expect(Flags.exists("flag")).to.equal(false)

			Flags.create("flag")
			expect(Flags.exists("flag")).to.equal(true)
		end)
	end)

	describe("read", function()
		it("should error if the flag does not exist", function()
			expect(function()
				Flags.read("flag")
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should return the flag data if it exists", function()
			Flags.create("flag")
			local flagConfig = Flags.read("flag")
			expect(flagConfig).to.be.ok()
			expect(flagConfig.active).to.equal(true)
			expect(flagConfig.retired).to.equal(false)
			expect(flagConfig.ruleSets).to.be.ok()
		end)
	end)

	describe("update", function()
		it("should error if the flag does not exist", function()
			expect(function()
				Flags.update("flag", { active = true })
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should update the flag data", function()
			Flags.create("flag")
			expect(Flags.read("flag").active).to.equal(true)

			Flags.update("flag", { active = false })
			expect(Flags.read("flag").active).to.equal(false)
		end)
	end)

	describe("retire", function()
		it("should error if the flag does not exist", function()
			expect(function()
				Flags.retire("flag")
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should retire the flag", function()
			Flags.create("flag")
			expect(Flags.read("flag").retired).to.equal(false)

			Flags.retire("flag")
			expect(Flags.read("flag").retired).to.equal(true)
		end)

		it("should un-retire the flag", function()
			Flags.create("flag", { retired = true })
			expect(Flags.read("flag").retired).to.equal(true)

			Flags.retire("flag", false)
			expect(Flags.read("flag").retired).to.equal(false)
		end)
	end)

	describe("destroy", function()
		it("should error if the flag does not exist", function()
			expect(function()
				Flags.destroy("flag")
			end).to.throw("Flag 'flag' doesn't exist.")
		end)

		it("should destroy the flag", function()
			Flags.create("flag")
			expect(Flags.exists("flag")).to.equal(true)

			Flags.destroy("flag")
			expect(Flags.exists("flag")).to.equal(false)
		end)
	end)

	describe("reset", function()
		local listener

		afterEach(function()
			if listener then
				listener.disconnect()
				listener = nil
			end
		end)

		it("should remove all flags", function()
			Flags.create("flag1")
			Flags.create("flag2")
			Flags.create("flag3")
			expect(Flags.exists("flag1")).to.equal(true)
			expect(Flags.exists("flag2")).to.equal(true)
			expect(Flags.exists("flag3")).to.equal(true)

			Flags.reset()
			expect(Flags.exists("flag1")).to.equal(false)
			expect(Flags.exists("flag2")).to.equal(false)
			expect(Flags.exists("flag3")).to.equal(false)
		end)

		it("should not notify by default", function()
			local callCount = 0
			listener = Flags.Changed:Connect(function()
				callCount += 1
			end)

			Flags.create("flag")
			expect(callCount).to.equal(1)

			Flags.reset()
			expect(callCount).to.equal(1)
		end)

		it("should notify when the parameter is set", function()
			local callCount = 0
			listener = Flags.Changed:Connect(function()
				callCount += 1
			end)

			Flags.create("flag")
			expect(callCount).to.equal(1)

			Flags.reset(true)
			expect(callCount).to.equal(2)
		end)
	end)

	describe("Changed", function()
		local listener

		afterEach(function()
			if listener then
				listener.disconnect()
				listener = nil
			end
		end)

		it("should fire when a flag is created", function()
			local callCount = 0
			listener = Flags.Changed:Connect(function()
				callCount += 1
			end)

			Flags.create("flag")
			expect(callCount).to.equal(1)
		end)

		it("should fire when a flag is updated", function()
			Flags.create("flag")

			local callCount = 0
			listener = Flags.Changed:Connect(function()
				callCount += 1
			end)

			Flags.update("flag", { active = false })
			expect(callCount).to.equal(1)
		end)

		it("should fire when a flag is retired", function()
			Flags.create("flag")

			local callCount = 0
			listener = Flags.Changed:Connect(function()
				callCount += 1
			end)

			Flags.retire("flag")
			expect(callCount).to.equal(1)
		end)

		it("should fire when a flag is destroyed", function()
			Flags.create("flag")

			local callCount = 0
			listener = Flags.Changed:Connect(function()
				callCount += 1
			end)

			Flags.destroy("flag")
			expect(callCount).to.equal(1)
		end)

		it("should provide the flag name", function()
			Flags.create("flag")

			local name
			listener = Flags.Changed:Connect(function(passedName)
				name = passedName
			end)

			Flags.update("flag", { active = false })
			expect(name).to.equal("flag")
		end)

		it("should provide the flag record", function()
			Flags.create("flag")

			local record
			listener = Flags.Changed:Connect(function(_, passedRecord)
				record = passedRecord
			end)

			Flags.update("flag", { active = false })
			expect(record).to.be.ok()
			expect(record.old).to.be.ok()
			expect(record.new).to.be.ok()
		end)

		it("should provide the old flag data", function()
			Flags.create("flag")

			local old
			listener = Flags.Changed:Connect(function(_, record)
				old = record.old
			end)

			Flags.update("flag", { active = false })
			expect(old).to.be.ok()
			expect(old.active).to.equal(true)
		end)

		it("should provide the new flag data", function()
			Flags.create("flag")

			local new
			listener = Flags.Changed:Connect(function(_, record)
				new = record.new
			end)

			Flags.update("flag", { active = false })
			expect(new).to.be.ok()
			expect(new.active).to.equal(false)
		end)

		it("should have no old flag data when the flag is created", function()
			local old
			listener = Flags.Changed:Connect(function(_, record)
				old = record.old
			end)

			Flags.create("flag")
			expect(old).to.never.be.ok()
		end)

		it("should have no new flag data when the flag is destroyed", function()
			Flags.create("flag")

			local new
			listener = Flags.Changed:Connect(function(_, record)
				new = record.new
			end)

			Flags.destroy("flag")
			expect(new).to.never.be.ok()
		end)
	end)
end
