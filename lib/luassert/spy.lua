local util = require 'luassert.util'

local spy = {
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

      called_with = function(self, args)
        for k,v in ipairs(self.calls) do
          if util.deepcompare(v, args) then
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

  on = function(self, callback_string)
    self[callback_string] = spy:new(self[callback_string])
    return self[callback_string]
  end
}

local function set_spy(state)
end

local function called_with(state, ...)
  if rawget(state, "payload") and rawget(state, "payload").called_with then
    return state.payload:called_with({...})
  else
    error("'called_with' must be chained after 'spy(aspy)'")
  end
end

local function called(state, num_times)
  if state.payload and state.payload.called then
    return state.payload:called(num_times)
  else
    error("'called_with' must be chained after 'spy(aspy)'")
  end
end

assert:register("modifier", "spy", set_spy)
assert:register("assertion", "called_with", called_with, "Function was not called with arguments")
assert:register("assertion", "called", called, "Function was not called")

return spy
