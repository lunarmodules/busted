require 'pl'

describe('require "pl" in this file', function()
  it('loads global environment with "List"', function()
    assert.is_not_nil(List)
  end)
end)

describe('require "socket" in another file', function()
  it('does not keep "socket" in environment', function()
    assert.is_nil(socket)
    assert.is_nil(package.loaded.socket)
  end)
end)
