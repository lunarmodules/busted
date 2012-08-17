local util = require 'luassert.util'
local s = require 'say.s'

local function unique(state, list, deep)
  for k,v in pairs(list) do
    for k2, v2 in pairs(list) do
      if k ~= k2 then
        if deep and util.deepcompare(v, v2, true) then
          return false, { v, v2 }
        else
          if v == v2 then
            return false, { v, v2 }
          end
        end
      end
    end
  end
  return true
end

local function equals(state, ...)
  local prev = nil
  for k,v in pairs({...}) do
    if prev ~= nil and prev ~= v then
      return false, {...}
    end
    prev = v
  end
  return true
end

local function same(state, ...)
  local prev = nil
  for k,v in pairs({...}) do
    if prev ~= nil then
      if type(prev) == 'table' and type(v) == 'table' then
        if not util.deepcompare(prev, v, true) then
          return false, {...}
        end
      else
        if prev ~= v then
          return false, {...}
        end
      end
    end
    prev = v
  end
  return true
end

local function truthy(state, var)
  local val = var ~= false and var ~= nil
  return val, var
end

local function falsy(state, var)
  return not truthy(state, var), var
end

local function has_error(state, func, err_expected)
  local err_actual = nil
  --must swap error functions to get the actual error message
  local old_error = error
  error = function(err)
    err_actual = err
    return old_error(err)
  end
  local status = pcall(func)
  error = old_error
  local val = not status and (err_expected == nil or same(state, err_expected, err_actual))

  return val, func
end

s:set("en", "assertion.same.positive", "Objects were not the same. Passed in:\n%s\nExpected:\n%s")
s:set("en", "assertion.same.negative", "Objects were the same. Passed in:\n%s\nExpected:\n%s")
assert:register("assertion", "same", same, "assertion.same.positive", "assertion.same.negative")

s:set("en", "assertion.equals.positive", "Objects were not the same. Passed in:\n%s\nExpected:\n%s")
s:set("en", "assertion.equals.negative", "Objects were equal. Passed in:\n%s\nExpected:\n%s")
assert:register("assertion", "equals", equals, "These values are not equal")
assert:register("assertion", "equal", equals, "assertion.equals.positive", "assertion.equals.negative")

s:set("en", "assertion.unique.positive", "Object was not unique:\n%s")
s:set("en", "assertion.unique.negative", "Object was unique:\n%s")
assert:register("assertion", "unique", unique, "These values are not unique")

s:set("en", "assertion.error.positive", "Error not thrown.")
s:set("en", "assertion.error.negative", "An error was thrown.\n%s")
assert:register("assertion", "error", has_error, "assertion.error.positive", "assertion.error.negative")
assert:register("assertion", "errors", has_error, "assertion.error.positive", "assertion.error.negative")

s:set("en", "assertion.truthy.positive", "Expected to be truthy, but value was:\n%s")
s:set("en", "assertion.truthy.negative", "Expected to not be truthy, but value was:\n%s")
assert:register("assertion", "truthy", truthy, "assertion.truthy.positive", "assertion.truthy.negative")

s:set("en", "assertion.falsy.positive", "Object was not falsy: %s")
s:set("en", "assertion.falsy.negative", "Object was falsy: %s")
assert:register("assertion", "falsy", falsy, "assertion.falsy.positive", "assertion.falsy.negative")
