local normalizeOptions = require(script.Parent.normalize)

return function()
	it("should return NormalizedOptions when provided nothing", function()
		local options = normalizeOptions()

		expect(options).to.be.a("table")
		expect(options.store).to.equal("FeatureFlags")
		expect(options.synchronizationInterval).to.equal(60)
	end)

	it("should return NormalizedOptions when provided an empty table", function()
		local options = normalizeOptions({})

		expect(options).to.be.a("table")
		expect(options.store).to.equal("FeatureFlags")
		expect(options.synchronizationInterval).to.equal(60)
	end)

	it("should set synchronizationInterval when provided a store", function()
		local options = normalizeOptions({
			store = "TestStore",
		})

		expect(options).to.be.a("table")
		expect(options.store).to.equal("TestStore")
		expect(options.synchronizationInterval).to.equal(60)
	end)

	it("should set store when provided a synchronizationInterval", function()
		local options = normalizeOptions({
			synchronizationInterval = 30,
		})

		expect(options).to.be.a("table")
		expect(options.store).to.equal("FeatureFlags")
		expect(options.synchronizationInterval).to.equal(30)
	end)

	it("should create the same configuration when provided all options", function()
		local options = normalizeOptions({
			store = "TestStore",
			synchronizationInterval = 30,
		})

		expect(options).to.be.a("table")
		expect(options.store).to.equal("TestStore")
		expect(options.synchronizationInterval).to.equal(30)
	end)
end
