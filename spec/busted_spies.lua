describe("Tests dealing with spies", function()
  local test = {
    key = function()
      return "derp"
    end
  }

  it("checks if a spy actually executes the internal function", function()
    spy.on(test, "key")
    assert(test.key() == "derp")
  end)

  pending("checks to see if spy keeps track of arguments", function()

  end)

  pending("checks to see if spy keeps track of number of calls", function()

  end)
end)
