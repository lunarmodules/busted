local util = require 'luassert.util'

local spy = {
  new = function(self, callback, options)
    return setmetatable(
      {
        calls = {},
        options = options,
        callback = callback,

        has_been_called = function(self, times)
          if times then
            return #self.calls == times
          end

          return #self.calls > 0
        end,

        has_been_called_with = function(self, ...)
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

          if self.options and self.options.pass_through then
            self.callback(...)
          end
        end
      }
    )
  end,

  spy_on = function(table, callback_string, options)
    local table_spy = spy:new(table[callback_string], options)
    table[callback_string] = table_spy

    return table_spy
  end
}

return spy
