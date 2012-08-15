local spy = require 'luassert.spy'

return function(self, key, func)
  self[key] = spy:new(func)
  return self[key]
end
