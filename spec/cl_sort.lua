-- supporting testfile; belongs to 'cl_spec.lua'

describe('Randomizing test order with --sort flag', function()
  local expected = {}
  local scratch = {}
  local order = {}

  for i = 1, 100 do
    table.insert(expected, i)
    table.insert(scratch, i)
  end

  while #scratch > 0 do
    local n = #scratch
    local k = math.random(n)
    local num = scratch[k]

    it(string.format('test number %03d', num), function()
      table.insert(order, num)
    end)

    scratch[k], scratch[n] = scratch[n], scratch[k]
    table.remove(scratch)
  end

  teardown('runs tests in sorted order', function()
    assert.are.same(expected, order)
  end)
end)
