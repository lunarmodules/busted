local utils = require 'spec.related_fixtures.src.utils'

describe('utils', function()
  it('adds numbers', function()
    assert.are.equal(5, utils.add(2, 3))
  end)

  it('subtracts numbers', function()
    assert.are.equal(1, utils.subtract(3, 2))
  end)
end)
