local util = require 'luassert.util'

local function has_error(func)
  return not pcall(func)
end

local function unique(list, deep)
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

local function equals(...)
  local prev = nil
  for k,v in pairs({...}) do
    if prev ~= nil and prev ~= v then
      return false
    end
    prev = v
  end
  return true
end

local function same(...)
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

local function truthy(var)
  return var ~= false and var ~= nil
end

local function falsy(var)
  return not truthy(var)
end

assert:register("same", same, "These values are not the same")
assert:register("equals", equals, "These values are not equal")
assert:register("unique", unique, "These values are not unique")
assert:register("error", has_error, "Expected error from function")
assert:register("truthy", truthy, "This value is not truthy")
assert:register("falsy", falsy, "This value is not falsy")
