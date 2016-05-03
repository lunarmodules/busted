local unexpected = {}
local order = {}
local orderfixed1 = {}
local orderfixed2 = {}

describe('Randomizing test order', function()
  randomize()

  for i = 1, 100 do
    table.insert(unexpected, i)

    it('does 100 its', function()
      table.insert(order, i)
    end)
  end
end)

describe('Randomizing test order with fixed seed as first arg', function()
  randomize(3210)

  for i = 1, 10 do
    it('does 10 its', function()
      table.insert(orderfixed1, i)
    end)
  end
end)

describe('Randomizing test order with fixed seed as second arg', function()
  randomize(true, 56789)

  for i = 1, 10 do
    it('does 10 its', function()
      table.insert(orderfixed2, i)
    end)
  end
end)

describe('Order of tests ran', function()
  local function shuffle(t, seed)
    math.randomseed(seed)
    local n = #t
    while n >= 1 do
      local k = math.random(n)
      t[n], t[k] = t[k], t[n]
      n = n - 1
    end
    return t
  end

  it('randomized', function()
    assert.are_not.same(unexpected, order)
  end)

  it('randomized with known random seed: 3210', function()
    local t = {1,2,3,4,5,6,7,8,9,10}
    assert.are.same(shuffle(t, 3210), orderfixed1)
  end)

  it('randomized with known random seed: 56789', function()
    local t = {1,2,3,4,5,6,7,8,9,10}
    assert.are.same(shuffle(t, 56789), orderfixed2)
  end)
end)

describe('Disabling randomized test order with randomize(false)', function()
  randomize()
  randomize(false)

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

describe('Disabling randomized test order with randomize(nil)', function()
  randomize()
  randomize(nil)

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
