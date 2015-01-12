
describe('tests require "busted"', function()
  local describe = describe
  local context = context
  local it = it
  local pending = pending
  local spec = spec
  local test = test
  local setup = setup
  local teardown = teardown
  local before_each = before_each
  local after_each = after_each

  it('does not import init', function()
    assert.is_nil(require 'busted'.init)
  end)

  it('imports file executor', function()
    assert.is_function(require 'busted'.file)
  end)

  it('imports describe/it/pending', function()
    assert.is_equal(describe, require 'busted'.describe)
    assert.is_equal(it, require 'busted'.it)
    assert.is_equal(pending, require 'busted'.pending)
  end)

  it('imports aliases', function()
    assert.is_equal(context, require 'busted'.context)
    assert.is_equal(spec, require 'busted'.spec)
    assert.is_equal(test, require 'busted'.test)
  end)

  it('imports support functions', function()
    assert.is_equal(setup, require 'busted'.setup)
    assert.is_equal(teardown, require 'busted'.teardown)
    assert.is_equal(before_each, require 'busted'.before_each)
    assert.is_equal(after_each, require 'busted'.after_each)
  end)

  it('functions cannot be overwritten', function()
    local foo = function() assert(false) end
    assert.has_error(function() require 'busted'.it = foo end)
    assert.is_equal(it, require 'busted'.it)
  end)

  it('cannot add new fields', function()
    local bar = function() assert(false) end
    assert.has_error(function() require 'busted'.foo = bar end)
  end)
end)
