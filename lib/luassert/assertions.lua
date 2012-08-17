local util = require 'luassert.util'
local s = require 'say.s'

local function unique(state, list, deep)
  for k,v in pairs(list) do
    for k2, v2 in pairs(list) do
      if k ~= k2 then
        if deep and util.deepcompare(v, v2, true) then
          return false
        else
          if v == v2 then
            return false
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
      return false
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
          return false
        end
      else
        if prev ~= v then
          return false
        end
      end
    end
    prev = v
  end
  return true
end

local function truthy(state, var)
  return var ~= false and var ~= nil
end

local function falsy(state, var)
  return not truthy(state, var)
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
  return not status and (err_expected == nil or same(state, err_expected, err_actual))
end

s("en", "assertion.same.positive", "Objects were not the same. Passed in:\n%s\nExpected:\n%s")
s("en", "assertion.same.negative", "Objects were the same. Passed in:\n%s\nExpected:\n%s")
assert:register("assertion", "same", same, "assertion.same.positive", "assertion.same.negative")

assert:register("assertion", "equals", equals, "These values are not equal")
assert:register("assertion", "equal", equals, "These values are not equal")
assert:register("assertion", "unique", unique, "These values are not unique")
assert:register("assertion", "error", has_error, "Expected error from function")
assert:register("assertion", "errors", has_error, "Expected error from function")
assert:register("assertion", "truthy", truthy, "This value is not truthy")
assert:register("assertion", "falsy", falsy, "This value is not falsy")
