pending('testing the done callback with tokens', function()

  it('Tests done call back ordered', function()
    async()
    stub(done, 'done_cb') -- create a stub to prevent actually calling 'done'
    done:wait_ordered('1', '2', '3')

    assert.has_no_error(function() done('1') end)
    assert.has_error(function() done('1') end) -- was already done
    assert.has_error(function() done('3') end) -- bad order
    assert.has_no_error(function() done('2') end)
    assert.has_error(function() done('this is no valid token') end)
    assert.has_no_error(function() done('3') end)
    assert.has_error(function() done('3') end) -- tokenlist empty by now
    assert.stub(done.done_cb).was.called(1)

    done.done_cb:revert() -- revert so test can complete
    done()
  end)

  it('Tests done call back unordered', function()
    async()
    stub(done, 'done_cb') -- create a stub to prevent actually calling 'done'
    done:wait_unordered('1', '2', '3')

    assert.has_no_error(function() done('1') end)
    assert.has_error(function() done('1') end) -- was already done
    assert.has_no_error(function() done('3') end) -- different order
    assert.has_no_error(function() done('2') end)
    assert.has_error(function() done('this is no valid token') end)
    assert.has_error(function() done('3') end) -- tokenlist empty by now
    assert.stub(done.done_cb).was.called(1)

    done.done_cb:revert() -- revert so test can complete
    done()
  end)

  it('Tests done call back defaulting to ordered', function()
    async()
    stub(done, 'done_cb') -- create a stub to prevent actually calling 'done'
    done:wait('1', '2')

    assert.has_error(function() done('2') end) -- different order
    assert.has_no_error(function() done('1') end)
    assert.has_no_error(function() done('2') end)

    done.done_cb:revert() -- revert so test can complete
    done()
  end)
end)

pending('testing done callbacks being provided for async tests', function()
  setup(function()
    async()
    assert.is_table(done)
    assert.is_function(done.wait)
    done()
  end)

  before_each(function()
    async()
    assert.is_table(done)
    assert.is_function(done.wait)
    done()
  end)

  after_each(function()
    async()
    assert.is_table(done)
    assert.is_function(done.wait)
    done()
  end)

  teardown(function()
    async()
    assert.is_table(done)
    assert.is_function(done.wait)
    done()
  end)

  it('Tests done callbacks being provided for async tests', function()
    async()
    assert.is_table(done)
    assert.is_function(done.wait)
    done()
  end)
end)
