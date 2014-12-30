-- supporting testfile; belongs to 'cl_spec.lua'

describe('Test error messages show file and line for', function()
  it('table errors #table', function()
    error({})
  end)

  it('nil errors #nil', function()
    error()
  end)

  it('string errors #string', function()
    error('error message')
  end)
end)
