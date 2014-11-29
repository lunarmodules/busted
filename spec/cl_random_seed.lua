-- supporting testfile; belongs to 'cl_spec.lua'
-- executed with --seed=12345
local order = {}

describe('Randomizing test order with pre-defined seed', function()
  randomize()

  for i = 1, 10 do
    it('does 10 its', function()
      table.insert(order, i)
    end)
  end
end)

describe('Order of tests ran', function()
  randomize()

  it('randomized with known random seed', function()
    local expected = { 9, 3, 5, 7, 6, 1, 8, 10, 4, 2 }
    assert.are.same(expected, order)
  end)
end)
