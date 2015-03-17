test_module = require 'spec.cl_test_module'

describe('Tests require "cl_test_module" in this file', function()
  it('loads environment with "cl_test_module"', function()
    assert.is_not_nil(test_module)
    assert.is_not_nil(package.loaded['spec.cl_test_module'])
  end)
end)

describe('Tests require "pl" in another file', function()
  it('does not keep "List" in environment', function()
    assert.is_nil(List)
    assert.is_nil(package.loaded['pl.List'])
  end)
end)
