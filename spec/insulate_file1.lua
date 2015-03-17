require 'pl'

describe('Tests require "pl" in this file', function()
  it('loads global environment with "List"', function()
    assert.is_not_nil(List)
  end)
end)

describe('Tests require "cl_test_module" in another file', function()
  it('does not keep test_module in environment', function()
    assert.is_nil(test_module)
    assert.is_nil(package.loaded['spec.cl_test_module'])
  end)
end)
