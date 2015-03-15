
describe('bad support functions should fail, sync test', function()
  describe('bad setup should properly fail a test', function()
    setup(function()
      error('failing a setup method')
    end)

    before_each(function() end)

    after_each(function() end)

    teardown(function() end)

    it('Tests nothing, should always fail due to failing support functions', function()
      assert(false)
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
      assert(false)
    end)
  end)


  describe('bad before_each should properly fail a test', function()
    setup(function() end)

    before_each(function()
      error('failing a before_each method')
    end)

    after_each(function() end)

    teardown(function() end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)


  describe('bad after_each should properly fail a test', function()
    setup(function() end)

    before_each(function() end)

    after_each(function()
      error('failing an after_each method')
    end)

    teardown(function() end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)

  describe('bad teardown should properly fail a test', function()
    setup(function() end)

    before_each(function() end)

    after_each(function() end)

    teardown(function()
      error('failing a teardown method')
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)

  describe('bad setup/teardown should properly fail a test', function()
    setup(function()
      error('failing a setup method')
    end)

    before_each(function() end)

    after_each(function() end)

    teardown(function()
      error('failing a teardown method')
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
      assert(false)
    end)
  end)
end)

describe('bad support functions should fail, async test', function()
  describe('bad setup should properly fail a test, async', function()
    setup(function()
      async()
      error('failing a setup method')
    end)

    before_each(function() end)

    after_each(function() end)

    teardown(function() end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)

  describe('bad before_each should properly fail a test, async', function()
    setup(function() end)

    before_each(function()
      async()
      error('failing a before_each method')
    end)

    after_each(function() end)

    teardown(function() end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)

  describe('bad after_each should properly fail a test, async', function()
    setup(function() end)

    before_each(function() end)

    after_each(function()
      async()
      error('failing an after_each method')
    end)

    teardown(function() end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)

  describe('bad teardown should properly fail a test, async', function()
    setup(function() end)

    before_each(function() end)

    after_each(function() end)

    teardown(function()
      async()
      error('failing a teardown method')
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
    end)
  end)

  describe('bad setup/teardown should properly fail a test, async', function()
    setup(function()
      async()
      error('failing a setup method')
    end)

    before_each(function() end)

    after_each(function() end)

    teardown(function()
      async()
      error('failing a teardown method')
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
      assert(false)
    end)

    it('Tests nothing, should always fail due to failing support functions', function()
      assert(false)
    end)
  end)

end)

