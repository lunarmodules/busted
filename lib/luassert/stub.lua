local mock = require 'luassert.mock'

return function(object)
  return mock(object, true)
end
