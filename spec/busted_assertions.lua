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

  it("Tests assert unique", function()
    local table2 = { derp = false}
    local table3 = { derp = true }
    local table1 = {table2,table3}
    assert.unique(table1, false)
  end)

  it("Tests IS operator", function()
    assert.is().equals(true, true)
  end)

  it("Tests NOT operator", function()
    assert.isnot().equals(true, true)
  end)

  it("Tests assert error", function()
    assert.error(function()error("test")end)
  end)
end)


