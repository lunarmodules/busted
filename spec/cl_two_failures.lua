-- supporting testfile; belongs to 'cl_spec.lua'

describe('Runs 2 failing tests', function()

  it('is failing test 1 #err1', function()
    assert(false, 'failed on test 1')
  end)

  it('is failing test 2 #err2', function()
    assert(false, 'failed on test 2')
  end)
end)

