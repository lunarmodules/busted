local spy = require 'luassert.spy'

return function(object, stub, self, key)
  local data_type = type(object)
  if data_type == "table" then
    for k,v in pairs(object) do
      object[k] = mock(v, nil, object, k)
    end
  elseif data_type == "function" then
    if stub then
      return spy:new()
    elseif self==nil then
      return spy:new(object)
    else
      return spy.on(self, key)
    end
  end
  return object
end
