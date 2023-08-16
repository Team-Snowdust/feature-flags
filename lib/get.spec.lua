local Package = script.Parent
local Flags = require(Package.Flags)
local Promise = require(Package.Parent.Promise)
local get = require(Package.get)

return function()
	describe("get", function()
		local promise

		afterEach(function()
			if promise then
				promise:cancel()
			end

			Flags.reset()
		end)

		it("should return a promise", function()
			promise = get("flag")
			expect(promise).to.be.ok()
			expect(Promise.is(promise)).to.equal(true)
		end)

		it("should resolve to the value of the flag", function()
			Flags.create("flag")
			promise = get("flag")
			local flag = promise:now():expect()

			expect(flag).to.be.ok()
		end)

		it("should resolve with a flag", function()
			Flags.create("flag")
			promise = get("flag")
			local flag = promise:now():expect()

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

		it("should resolve with a flag that has the correct name", function()
			Flags.create("flag")
			promise = get("flag")
			local flag = promise:now():expect()

			expect(flag.name).to.equal("flag")
		end)

		it("should resolve with a flag that has the correct active state", function()
			Flags.create("flag")
			promise = get("flag")
			local flag = promise:now():expect()

			expect(flag.isActive()).to.equal(true)
		end)

		it("should not resolve when no flag exists", function()
			promise = get("flag")
			local resolved = promise:now():await()

			expect(resolved).to.equal(false)
		end)

		it("should not resolve until the flag is created", function()
			promise = get("flag")
			local resolved = promise:now():await()

			expect(resolved).to.equal(false)

			Flags.create("flag")
			resolved = promise:now():await()

			expect(resolved).to.equal(true)
		end)
	end)
end
