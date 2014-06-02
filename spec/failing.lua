describe('failure', function()
  it('fails', function()
    assert(false)
  end)

  it('fails again', function()
    assert.are_equal(1,2)
  end)

  it('fails with a table', function()
    error({ test = 'true'  })
  end)
end)
