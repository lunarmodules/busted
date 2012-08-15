describe("Tests dealing with mocks", function()
  local test = {
    {
      key = function()
        return "derp"
      end
    }
  }

  it("doesn't error", function()
      assert(type(mock(test)) == "table")
  end)
end)
