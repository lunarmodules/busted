local unexpected = {}
local order = {}

randomize()

for i = 1, 100 do
  table.insert(unexpected, i)

  it('does 100 its', function()
    table.insert(order, i)
  end)
end

teardown(function()
  assert.are_not.same(unexpected, order)
end)
