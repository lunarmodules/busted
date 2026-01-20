local core = require 'spec.related_fixtures.src.core'

describe('core', function()
  it('calculates correctly', function()
    assert.are.equal(10, core.calculate(2, 3))
  end)
end)
