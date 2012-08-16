describe("Tests dealing with spies", function()
  local test = {}

  before_each(function()
    test = {key = function()
      return "derp"
    end}
  end)
--[[
  it("checks if a spy actually executes the internal function", function()
    spy.on(test, "key")
    assert(test.key() == "derp")
  end)
]]
  it("checks to see if spy keeps track of arguments", function()

    test.key = spy.on(test, "key")

    test.key("derp")
    assert.spy(test.key).was.called_with("derp")
    assert.errors(function() assert.spy(test.key).was.called_with("herp") end)
  end)

  it("checks to see if spy keeps track of number of calls", function()
     test.key = spy.on(test, "key")
     test.key()
     test.key("test")
     assert.spy(test.key).was.called(2)
  end)
end)
