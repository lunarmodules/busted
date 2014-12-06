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
    math.randomseed(12345)
    local t = {}
    for i = 1, 10 do
      table.insert(t, i)
    end
    local n = #t
    while n >= 1 do
      local k = math.random(n)
      t[n], t[k] = t[k], t[n]
      n = n - 1
    end
    local expected = t
    assert.are.same(expected, order)
  end)
end)
