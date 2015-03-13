-- supporting testfile; belongs to 'cl_spec.lua'

describe('Runs no setup/teardown in empty suites', function()
  setup(function()
    assert(false)
  end)

  describe('Nested', function()
    describe('Nested again', function()
    end)

    teardown(function()
      assert(false)
    end)
  end)

  teardown(function()
    assert(false)
  end)
end)

