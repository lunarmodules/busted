local unexpected = {}
local order = {}

describe('Randomizing test order', function()
  randomize()

  for i = 1, 100 do
    table.insert(unexpected, i)

    it('does 1000 its', function()
      table.insert(order, i)
    end)
  end
end)

describe('Order of tests ran', function()
  it('randomized', function()
    assert.are_not.same(unexpected, order)
  end)
end)
