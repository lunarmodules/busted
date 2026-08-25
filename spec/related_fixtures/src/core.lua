local utils = require 'spec.related_fixtures.src.utils'

local core = {}

function core.calculate(a, b)
  return utils.add(a, b) * 2
end

return core
