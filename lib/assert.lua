local util = require 'lib/util'
old_assert = assert

assert = {}
assert.mod = true
assert.assertions = {}
assert.raw = {}

assert.__assertionMeta = {}
function assert.__assertionMeta.__index(table, key)
  rawget(assert, "assertions")[key:lower()].mod = rawget(table, "mod")
  return rawget(assert, "assertions")[key:lower()]
end

assert.__callerMeta = {}
function assert.__callerMeta.__call(assertion, ...)
  if rawget(rawget(assert, "assertions")[rawget(assertion, "name"):lower()], "assertion")(...) ~= rawget(assertion, "mod") then
    error(rawget(assertion, "errormessage"))
  end
  return true
end

assert.__meta = {}
function assert.__meta.__call(table, bool, message)
  if not bool then
    error(message or "assertion failed!")
  end
  return true
end

function assert.__meta.__index(table, key)
  if rawget(table, "assertions")[key:lower()] then
    rawget(table, "assertions")[key:lower()].mod = rawget(table, "mod")
    return rawget(table, "assertions")[key:lower()]
  else
    if rawget(table, "raw")[key:lower()] ~= nil then
      if type(rawget(table, "raw")[key:lower()]) == 'function' then
        return rawget(table, "raw")[key:lower()]()
      else
        return rawget(table, "raw")[key:lower()]
      end
    else
      return rawget(table, key:lower())
    end
  end
end

function assert:register(name, assertion, errormessage)
  rawget(self, "assertions")[name:lower()] = setmetatable({mod=false, assertion = assertion, name = name:lower(), errormessage=errormessage}, rawget(assert, "__callerMeta"))
end

function assert.raw.is()
  return setmetatable({
    mod = true
  }, rawget(assert, "__assertionMeta"))
end

function assert.raw.isnot()
  return setmetatable({
    mod = false
  }, rawget(assert, "__assertionMeta"))
end

function assert.raw.all(list)
  error("NOT IMPLEMENTED")
end

function assert.raw.none(list)
  error("NOT IMPLEMENTED")
end

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

assert:register("same", same, "These values are not the same")
assert:register("equals", equals, "These values are not equal")
assert:register("unique", unique, "These values are not unique")
assert:register("error", has_error, "Expected error from function")

assert=setmetatable(assert, assert.__meta)
