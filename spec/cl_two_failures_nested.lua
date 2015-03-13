-- supporting testfile; belongs to 'cl_spec.lua'

describe('Runs 3 failing tests in nested suites', function()
  local setup_missed = true
  setup(function()
    setup_missed = false
  end)

  describe('Nested', function()
    describe('Nested again', function()
      it('is failing test 1 #err1', function()
        assert(setup_missed, 'failed on test 1')
      end)

      it('is failing test 2 #err2', function()
        assert(setup_missed, 'failed on test 2')
      end)
    end)

    it('is failing test 3 #err3', function()
      assert(setup_missed, 'failed on test 3')
    end)

    teardown(function()
      assert(setup_missed)
    end)
  end)

  teardown(function()
    assert(setup_missed)
  end)
end)

