-- supporting testfile; belongs to 'cl_spec.lua'
local unexpected = {}
local order = {}

describe('Randomizing test order with --shuffle flag', function()
  for i = 1, 100 do
    table.insert(unexpected, i)

    it('does 100 its', function()
      table.insert(order, i)
    end)
  end

  teardown('runs tests in randomized order', function()
    assert.are_not.same(unexpected, order)
  end)
end)

