-- Fixture for cl_spec.lua

describe('Tests retries', function()
  local attempts = 0

  it('succeeds once retried', function()
    set_retries(2)
    attempts = attempts + 1
    assert.is_equal(3, attempts)
  end)

  it('reports one error when retries are exhausted', function()
    set_retries(2)
    error('never succeeds')
  end)

  it('rejects a non-integer retry count', function()
    set_retries(math.huge)
  end)
end)
