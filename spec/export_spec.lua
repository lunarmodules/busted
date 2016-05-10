
describe('tests require "busted"', function()
  local describe = describe
  local context = context
  local insulate = insulate
  local expose = expose
  local it = it
  local pending = pending
  local spec = spec
  local test = test
  local setup = setup
  local teardown = teardown
  local before_each = before_each
  local after_each = after_each
  local lazy_setup = lazy_setup
  local lazy_teardown = lazy_teardown
  local strict_setup = strict_setup
  local strict_teardown = strict_teardown

  it('does not export init', function()
    assert.is_nil(require 'busted'.init)
  end)

  it('does not export file executor', function()
    assert.is_nil(require 'busted'.file)
  end)

  it('exports describe/it/pending', function()
    assert.is_equal(describe, require 'busted'.describe)
    assert.is_equal(it, require 'busted'.it)
    assert.is_equal(pending, require 'busted'.pending)
  end)

  it('exports aliases', function()
    assert.is_equal(context, require 'busted'.context)
    assert.is_equal(insulate, require 'busted'.insulate)
    assert.is_equal(expose, require 'busted'.expose)
    assert.is_equal(spec, require 'busted'.spec)
    assert.is_equal(test, require 'busted'.test)
  end)

  it('exports support functions', function()
    assert.is_equal(setup, require 'busted'.setup)
    assert.is_equal(teardown, require 'busted'.teardown)
    assert.is_equal(lazy_setup, require 'busted'.lazy_setup)
    assert.is_equal(lazy_teardown, require 'busted'.lazy_teardown)
    assert.is_equal(strict_setup, require 'busted'.strict_setup)
    assert.is_equal(strict_teardown, require 'busted'.strict_teardown)
    assert.is_equal(before_each, require 'busted'.before_each)
    assert.is_equal(after_each, require 'busted'.after_each)
  end)

  it('exports assert, mocks, and matchers', function()
    assert.is_equal(assert, require 'busted'.assert)
    assert.is_equal(spy, require 'busted'.spy)
    assert.is_equal(mock, require 'busted'.mock)
    assert.is_equal(stub, require 'busted'.stub)
    assert.is_equal(match, require 'busted'.match)
  end)

  it('exports publish/subscribe', function()
    local foo
    local publish = require 'busted'.publish
    local subscribe = require 'busted'.subscribe
    local unsubscribe = require 'busted'.unsubscribe
    local sub = subscribe({'export_test'}, function(...) foo = {...} end)
    publish({'export_test'}, 'value1', 'value2' )
    local unsub = unsubscribe(sub.id, {'export_test'})
    publish({'export_test'}, 'new_value1', 'new_value2')
    assert.is_same({'value1', 'value2'}, foo)
    assert.is_equal(sub, unsub)
  end)

  it('exports other functions/variables', function()
    assert.is_function(require 'busted'.bindfenv)
    assert.is_function(require 'busted'.fail)
    assert.is_function(require 'busted'.gettime)
    assert.is_function(require 'busted'.monotime)
    assert.is_function(require 'busted'.sleep)
    assert.is_function(require 'busted'.parent)
    assert.is_function(require 'busted'.children)
    assert.is_string(require 'busted'.version)
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
