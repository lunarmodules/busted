socket = require 'socket'

describe('require "socket" in this file', function()
  it('loads environment with "socket"', function()
    assert.is_not_nil(socket)
  end)
end)

describe('require "pl" in another file', function()
  it('does not keep "List" in environment', function()
    assert.is_nil(List)
    assert.is_nil(package.loaded['pl.List'])
  end)
end)
