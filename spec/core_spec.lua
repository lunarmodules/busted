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

  it("runs once to fire an after_each and then", function() end)
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

  it("checks if both were called", function() end)
  it("runs again just to be sure", function() end)
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
      assert(test_val == 1)
    end)
  end)
end)

describe("Before_each on describe blocks, part II", function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  describe("A block", function()
    before_each(function()
      test_val = test_val + 1
    end)

    it("derps", function() end)
    it("herps", function() end)
  end)

  it("checks the value", function()
    assert(test_val == 3)
  end)
end)

describe("A failing test", function()
  it("explodes", function()
    assert.has.error(function() assert(false, "this should fail") end)
  end)
end)

describe("tagged tests #test", function()
  it("runs", function()
    assert(true)
  end)
end)
