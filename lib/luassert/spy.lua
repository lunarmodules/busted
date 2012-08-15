local util = require 'luassert.util'

return {
  new = function(self, callback)
    return setmetatable(
    {
      calls = {},
      callback = callback or function() end,

      called = function(self, times)
        if times then
          return #self.calls == times
        end

        return #self.calls > 0
      end,

      called_with = function(self, ...)
        for k,v in ipairs(self.calls) do
          if util.deepcompare(v, { ... }) then
            return true
          end
        end

        return false
      end
    },
    {
      __call = function(self, ...)
        table.insert(self.calls, { ... })
        return self.callback(...)
      end
    })
  end,

  on = function(table, callback_string)
    table[callback_string] = spy:new(table[callback_string])
    return table[callback_string]
  end
}
