local feature = require 'spec.related_fixtures.src.feature'

describe('feature', function()
  it('processes correctly', function()
    assert.are.equal(20, feature.process(2, 3))
  end)
end)
