local core = require 'spec.related_fixtures.src.core'

local feature = {}

function feature.process(a, b)
  return core.calculate(a, b) + 10
end

return feature
