-- supporting testfile; belongs to 'cl_spec.lua'

describe('Tests the busted error detection through the commandline', function()

  it('is a test that throws an error #testerr', function()
    error('force an error')
  end)

  it('is a test with a Lua error #luaerr', function()
    local foo
    foo.bar = nil
  end)
end)

