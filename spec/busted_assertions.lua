describe("Test Assertions", function()

  it("Tests Assert Same", function()
    local table1 = { derp = false}
    local table2 = { derp = false}
    assert.same(table1, table2)
  end)

  it("Tests Assert equals", function()
    local table1 = { derp = false}
    local table2 = table1
    assert.equals(table1, table2)
  end)
end)


