describe("Tests dealing with mocks", function()
  local test = {}

  before_each(function()
    test = {
      key = function()
        return "derp"
      end
    }
  end)

  it("makes sure we're returning the same table", function()
    local val = tostring(test)
    assert(type(mock(test)) == "table")
    assert(tostring(mock(test)) == val)
  end)

  it("makes sure function calls are spies", function()
    local val = tostring(test)
    assert(type(test.key) == "function")
    mock(test)
    assert(type(test.key) == "table")
    assert(test.key() == "derp")
  end)

  it("makes sure function calls are stubs when specified", function()
    local val = tostring(test)
    assert(type(test.key) == "function")
    mock(test, true)
    assert(type(test.key) == "table")
    assert(test.key() == nil)
  end)
end)
