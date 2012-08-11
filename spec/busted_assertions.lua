describe("Test Assertions", function()
  it("Checks to see if tables 1 and 2 are the same", function()
    local table1 = { derp = false}
    local table2 = { derp = false}
    assert.same(table1, table2)
  end)

  it("Checks to see if tables 1 and 2 are equal", function()
    local table1 = { derp = false}
    local table2 = table1
    assert.equals(table1, table2)
  end)

  it("Checks to see if table1 only contains unique elements", function()
    local table2 = { derp = false}
    local table3 = { derp = true }
    local table1 = {table2,table3}
    local tablenotunique = {table2,table2}
    assert.is.unique(table1)
    assert.not.unique(tablenotunique)
  end)

  it("Ensures the is operator doesn't change the behavior of equals", function()
    assert.is.equals(true, true)
  end)

  it("Ensures the not operator does change the behavior of equals", function()
    assert.isnot.equals(true, false)
  end)

  it("Ensures that error only throws an error when the first argument function does not throw an error", function()
    assert.error(function() error("test") end)
  end)

  it("Checks to see if var is truthy", function()
    assert.not.truthy(nil)
    assert.is.truthy(true)
    assert.is.truthy({})
    assert.is.truthy(function()end)
    assert.is.truthy("")
    assert.not.truthy(false)
  end)

  it("Checks to see if var is falsy", function()
    assert.is.falsy(nil)
    assert.not.falsy(true)
    assert.not.falsy({})
    assert.not.falsy(function()end)
    assert.not.falsy("")
    assert.is.falsy(false)
  end)

end)


