-- supporting testfile; belongs to 'cl_spec.lua'

describe('Tests the busted pending functions through the commandline', function()

  it('is a test with a pending', function()
    pending('finish this test later')
    error('should never get here')
  end)

  pending('is a pending inside a describe', function()
    it('this test does not run', function()
      error('this should not run')
    end)
  end)
end)

