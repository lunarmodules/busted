--ensure environment is set up
assert(type(file) == 'nil')
assert(type(describe) == 'function')
assert(type(context) == 'function')
assert(type(it) == 'function')
assert(type(spec) == 'function')
assert(type(test) == 'function')
assert(type(before_each) == 'function')
assert(type(after_each) == 'function')
assert(type(spy) == 'table')
assert(type(stub) == 'table')
assert(type(mock) == 'table')
assert(type(match) == 'table')
assert(type(assert) == 'table')

describe('Before each', function()
  local test_val = false

  before_each(function()
    test_val = true
  end)

  it('is called', function()
    assert(test_val)
  end)
end)

describe('After each', function()
  local test_val = false

  after_each(function()
    test_val = true
  end)

  it('runs once to fire an after_each and then', function() end)
  it('checks if after_each was called', function()
    assert(test_val)
  end)
end)

describe('Both before and after each', function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  after_each(function()
    test_val = test_val + 1
  end)

  it('checks if both were called', function() end)
  it('runs again just to be sure', function() end)

  it('checks the value', function() 
    assert(test_val == 5)
  end)
end)

describe('Before_each on describe blocks', function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  describe('A block', function()
    it('derps', function()
      assert(test_val == 1)
    end)

    it('herps', function()
      assert(test_val == 2)
    end)
  end)
end)

describe('Before_each on describe blocks, part II', function()
  local test_val = 0

  before_each(function()
    test_val = test_val + 1
  end)

  it('checks the value', function()
    assert.are.equal(1, test_val)
  end)

  describe('A block', function()
    before_each(function()
      test_val = test_val + 1
    end)

    it('derps', function() end) --add two: two before-eaches
    it('herps', function() end)

    it('checks the value', function()
      assert.equal(7, test_val)
    end)
  end)
end)

describe('A failing test', function()
  it('explodes', function()
    assert.has.error(function() assert(false, 'this should fail') end)
  end)
end)

describe('tagged tests #test', function()
  it('runs', function()
    assert(true)
  end)
end)

describe('Testing test order', function()
  local testorder, level = '', 0

  local function report_level(desc)
    testorder = testorder .. string.rep(' ', level * 2) .. desc .. '\n'
  end

  describe('describe, level A', function()

    setup(function()
      report_level('setup A')
      level = level + 1
    end)

    teardown(function()
      level = level - 1
      report_level('teardown A')
    end)

    before_each(function()
      report_level('before_each A')
      level = level + 1
    end)

    after_each(function()
      level = level - 1
      report_level('after_each A')
    end)

    it('tests A one', function()
      report_level('test A one')
    end)

    it('tests A two', function()
      report_level('test A two')
    end)

    describe('describe level B', function()

      setup(function()
        report_level('setup B')
        level = level + 1
      end)

      teardown(function()
        level = level - 1
        report_level('teardown B')
      end)

      before_each(function()
        report_level('before_each B')
        level = level + 1
      end)

      after_each(function()
        level = level - 1
        report_level('after_each B')
      end)

      it('tests B one', function()
        report_level('test B one')
      end)

      it('tests B two', function()
        report_level('test B two')
      end)
    end)

    it('tests A three', function()
      report_level('test A three')
    end)
  end)

  describe('Test testorder', function()
    it('verifies order of execution', function()
    local expected = [[setup A
  before_each A
    test A one
  after_each A
  before_each A
    test A two
  after_each A
  setup B
    before_each A
      before_each B
        test B one
      after_each B
    after_each A
    before_each A
      before_each B
        test B two
      after_each B
    after_each A
  teardown B
  before_each A
    test A three
  after_each A
teardown A
]]
      assert.is.equal(expected, testorder)
    end)
  end)
end)

describe('finally callback is called in case of success', function()
  local f = spy.new(function() end)

  it('write variable in finally', function()
    finally(f)
    assert.is_true(true)
  end)

  it('ensures finally was called', function()
    assert.spy(f).was_called(1)
  end)
end)

describe('tests environment', function()
  global = 'global'

  setup(function()
    globalsetup = 'globalsetup'
  end)

  teardown(function()
    globalteardown = 'globalteardown'
  end)

  before_each(function()
    globalbefore = 'globalbefore'
  end)

  after_each(function()
    globalafter = 'globalafter'
  end)

  it('cannot access globals which have not been created yet', function()
    assert.equal(nil, globalafter)
    assert.equal(nil, globalteardown)
    notglobal = 'notglobal'
  end)

  it('can access globals', function()
    assert.equal('global', global)
    assert.equal('globalsetup', globalsetup)
    assert.equal('globalbefore', globalbefore)
    assert.equal('globalafter', globalafter)
    notglobal = 'notglobal'
  end)

  it('cannot access globals set in siblings', function()
    assert.equal(nil, notglobal)
  end)

  describe('can access parent globals', function()
    it('from child', function()
      assert.equal('global', global)
      assert.equal('globalsetup', globalsetup)
      assert.equal('globalbefore', globalbefore)
      assert.equal('globalafter', globalafter)
    end)
  end)

  describe('cannot access globals set in children', function()
    it('has a global', function()
      notglobal = 'notglobal'
    end)

    assert.are.equal(notglobal, nil)
  end)
end)

describe('tests clean environment', function()
  it('globals in previous describe are not available', function()
    assert.is_nil(global)
    assert.is_nil(globalsetup)
    assert.is_nil(globalbefore)
    assert.is_nil(globalafter)
    assert.is_nil(globalteardown)
  end)
end)

describe 'tests syntactic sugar' (function()
   it 'works' (function()
      assert(true)
   end)
end)

describe('tests aliases', function()
  local test_val = 0

  context('runs context alias', function()
    setup(function()
      test_val = test_val + 1
    end)

    before_each(function()
      test_val = test_val + 1
    end)

    after_each(function()
      test_val = test_val + 1
    end)

    teardown(function()
      test_val = test_val + 1
    end)

    spec('runs spec alias', function()
      test_val = test_val + 1
    end)

    test('runs test alias', function()
      test_val = test_val + 1
    end)
  end)

  it('checks aliases were executed', function()
    assert.is_equal(8, test_val)
  end)
end)

describe('tests unsupported functions', function()
  it('it block does not have file executor', function()
    assert.is_nil(file)
  end)

  it('it block throws error on describe/context', function()
    assert.has_error(describe, "'describe' not supported inside current context block")
    assert.has_error(context, "'context' not supported inside current context block")
  end)

  it('it block throws error on insulate/expose', function()
    assert.has_error(insulate, "'insulate' not supported inside current context block")
    assert.has_error(expose, "'expose' not supported inside current context block")
  end)

  it('it block throws error on it/spec/test', function()
    assert.has_error(it, "'it' not supported inside current context block")
    assert.has_error(spec, "'spec' not supported inside current context block")
    assert.has_error(test, "'test' not supported inside current context block")
  end)

  it('it block throws error on setup/before_each/after_each/teardown', function()
    assert.has_error(setup, "'setup' not supported inside current context block")
    assert.has_error(before_each, "'before_each' not supported inside current context block")
    assert.has_error(after_each, "'after_each' not supported inside current context block")
    assert.has_error(teardown, "'teardown' not supported inside current context block")
  end)

  it('it block throws error on lazy/strict setup/teardown', function()
    assert.has_error(lazy_setup, "'lazy_setup' not supported inside current context block")
    assert.has_error(lazy_teardown, "'lazy_teardown' not supported inside current context block")
    assert.has_error(strict_setup, "'strict_setup' not supported inside current context block")
    assert.has_error(strict_teardown, "'strict_teardown' not supported inside current context block")
  end)

  it('it block throws error on randomize', function()
    assert.has_error(randomize, "'randomize' not supported inside current context block")
  end)

  it('finaly block throws error on pending', function()
    finally(function()
      assert.has_error(pending, "'pending' not supported inside current context block")
    end)
  end)
end)

describe('tests unsupported functions in setup/before_each/after_each/teardown', function()
  local function testUnsupported()
    assert.is_nil(file)
    assert.is_nil(finally)
    assert.has_error(randomize, "'randomize' not supported inside current context block")

    assert.has_error(describe, "'describe' not supported inside current context block")
    assert.has_error(context, "'context' not supported inside current context block")

    assert.has_error(insulate, "'insulate' not supported inside current context block")
    assert.has_error(expose, "'expose' not supported inside current context block")

    assert.has_error(pending, "'pending' not supported inside current context block")

    assert.has_error(it, "'it' not supported inside current context block")
    assert.has_error(spec, "'spec' not supported inside current context block")
    assert.has_error(test, "'test' not supported inside current context block")

    assert.has_error(setup, "'setup' not supported inside current context block")
    assert.has_error(before_each, "'before_each' not supported inside current context block")
    assert.has_error(after_each, "'after_each' not supported inside current context block")
    assert.has_error(teardown, "'teardown' not supported inside current context block")

    assert.has_error(lazy_setup, "'lazy_setup' not supported inside current context block")
    assert.has_error(lazy_teardown, "'lazy_teardown' not supported inside current context block")
    assert.has_error(strict_setup, "'strict_setup' not supported inside current context block")
    assert.has_error(strict_teardown, "'strict_teardown' not supported inside current context block")
  end

  setup(testUnsupported)
  teardown(testUnsupported)
  before_each(testUnsupported)
  after_each(testUnsupported)

  it('tests nothing, all tests performed by support functions', function()
  end)
end)

describe('tests strict setup/teardown', function()
  local setup_count = 0
  local teardown_count = 0

  describe('in describe with no tests', function()
    strict_setup(function()
      setup_count = setup_count + 1
    end)

    strict_teardown(function()
      teardown_count = teardown_count + 1
    end)
  end)

  it('executes setup/teardown in previous block with no tests', function()
    assert.is_equal(1, setup_count)
    assert.is_equal(1, teardown_count)
  end)
end)

describe('tests lazy setup/teardown not run if no tests found in block', function()
  lazy_setup(function()
    assert(false, 'setup should not execute since no tests')
  end)

  lazy_teardown(function()
    assert(false, 'teardown should not execute since no tests')
  end)
end)

describe('tests lazy setup/teardown in describe with no tests', function()
  local setup_count = 0
  local teardown_count = 0

  describe('with nested describe with no tests', function()
    lazy_setup(function()
      setup_count = setup_count + 1
    end)

    lazy_teardown(function()
      teardown_count = teardown_count + 1
    end)

    describe('with inner nested describe with no tests', function()
      lazy_setup(function()
        setup_count = setup_count + 1
      end)

      lazy_teardown(function()
        teardown_count = teardown_count + 1
      end)
    end)
  end)

  it('does not run setup/teardown', function()
    assert.is_equal(0, setup_count)
    assert.is_equal(0, teardown_count)
  end)
end)

describe('tests lazy setup/teardown with nested tests', function()
  local setup_count = 0
  local teardown_count = 0

  lazy_setup(function()
    setup_count = setup_count + 1
  end)

  lazy_teardown(function()
    teardown_count = teardown_count + 1
  end)

  describe('nested describe with tests', function()
    lazy_setup(function()
      setup_count = setup_count + 1
    end)

    lazy_teardown(function()
      teardown_count = teardown_count + 1
    end)

    it('runs all setups', function()
      assert.is_equal(2, setup_count)
    end)

    it('runs setups only once', function()
      assert.is_equal(2, setup_count)
    end)

    it('runs teardown after all tests complete', function()
      assert.is_equal(0, teardown_count)
    end)
  end)

  describe('second nested describe', function()
    lazy_teardown(function()
      teardown_count = teardown_count + 1
    end)

    it('verify teardown ran after previous describe completes', function()
      assert.is_equal(1, teardown_count)
    end)
  end)

  describe('another nested describe with tests', function()
    lazy_setup(function()
      setup_count = setup_count + 1
    end)

    it('runs setup for new describe', function()
      assert.is_equal(3, setup_count)
    end)

    it('verify teardown ran after previous describe completes', function()
      assert.is_equal(2, teardown_count)
    end)
  end)
end)
