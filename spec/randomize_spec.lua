local unexpected = {}
local order = {}

describe('Randomizing test order', function()
  randomize()

  for i = 1, 100 do
    table.insert(unexpected, i)

    it('does 100 its', function()
      table.insert(order, i)
    end)
  end
end)

describe('Order of tests ran', function()
  it('randomized', function()
    assert.are_not.same(unexpected, order)
  end)
end)

describe('Disabling randomized test order', function()
  randomize()
  norandomize()

  local expected = {}
  local order = {}

  for i = 1, 100 do
    table.insert(expected, i)

    it('does 100 its', function()
      table.insert(order, i)
    end)
  end

  it('does not randomize tests', function()
    assert.are.same(expected, order)
  end)
end)
