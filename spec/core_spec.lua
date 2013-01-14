require('busted')

assert(type(describe) == "function")
assert(type(it) == "function")
assert(type(before_each) == "function")
assert(type(after_each) == "function")
assert(type(spy) == "table")
assert(type(mock) == "function")

local test_val = false

describe("Test Case", function()
  local test_val = true
  assert(test_val)
end)

describe("Test case", function()
  local test_val = false
  it("changes test_val to true", function()
    test_val = true
    assert(test_val)
  end)
end)

describe("Before each", function()
  local test_val = false

  before_each(function()
    test_val = true
  end)

  it("is called", function()
    assert(test_val)
  end)
end)

describe("After each", function()
  local test_val = false

  after_each(function()
    test_val = true
  end)

  it("runs once to fire an after_each and then", function() assert(true) end)
  it("checks if after_each was called", function()
   assert(test_val)
  end)
end)

describe("Both before and after each", function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  after_each(function()
    test_val = test_val + 1
  end)

  it("checks if both were called", function() assert(true) end)
  it("runs again just to be sure", function() assert(true) end)

  it("checks the value", function() 
    assert(test_val == 5)
  end)
end)

describe("Before_each on describe blocks", function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  describe("A block", function()
    it("derps", function()
      assert(test_val == 1)
    end)

    it("herps", function()
      assert(test_val == 2)
    end)
  end)
end)

describe("Before_each on describe blocks, part II", function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  it("checks the value", function()
    assert.are.equal(1, test_val)
  end)

  describe("A block", function()
    before_each(function()
      test_val = test_val + 1
    end)

    it("derps", function() assert(true) end) --add two: two before-eaches
    it("herps", function() assert(true) end)

    it("checks the value", function()
      assert(test_val == 7)
    end)
  end)
end)

describe("A failing test", function()
  it("explodes", function()
    assert.has.error(function() error(false, "this should fail") end)
  end)
end)

describe("tagged tests #test", function()
  it("runs", function()
    assert(true)
  end)
end)
