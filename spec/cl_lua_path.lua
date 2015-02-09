-- supporting testfile; belongs to 'cl_spec.lua'

describe('Tests --lpath prepends to package.path', function()
  it('require test module', function()
    local mod = require('cl_test_module')
    assert.is_equal('test module', mod)
  end)
end)
