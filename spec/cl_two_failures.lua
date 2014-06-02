-- supporting testfile; belongs to 'cl_spec.lua'

describe('Runs 2 failing tests', function()

  it('is failing test 1', function()
    error('error on test 1')
  end)

  it('is failing test 2', function()
    error('error on test 2')
  end)
end)

