local util = require 'lib/util'

assert = {}
assert.mod = true
assert.assertions = {}

assert.__assertionMeta = {}
function assert.__assertionMeta.__index(table, key)
  rawget(assert, "assertions")[key:lower()].mod = rawget(table, "mod")
  return rawget(assert, "assertions")[key:lower()]
end

assert.__callerMeta = {}
function assert.__callerMeta.__call(assertion, ...)
  print(json.encode(arg))
  print(rawget(assertion, "mod"))
  if rawget(rawget(assert, "assertions")[rawget(assertion, "name"):lower()], "assertion")(unpack(arg)) == rawget(assertion, "mod") then
    error(rawget(assertion, "errormessage"))
  end
  return true
end

assert.__meta = {}
function assert.__meta.__call(table, bool, message)
  if not bool then
    error(message)
  end
  return true
end

function assert.__meta.__index(table, key)
  if rawget(table, "assertions")[key:lower()] then
    rawget(table, "assertions")[key:lower()].mod = rawget(table, "mod")
    return rawget(table, "assertions")[key:lower()]
  else
    return rawget(table, key:lower())
  end
end

function assert:register(name, assertion, errormessage)
  rawget(self, "assertions")[name:lower()] = setmetatable({mod=false, assertion = assertion, name = name:lower(), errormessage=errormessage}, rawget(assert, "__callerMeta"))
end

function assert.is()
  return setmetatable({
    mod = true
  }, rawget(assert, "__assertionMeta"))
end

function assert.isnot()
  return setmetatable({
    mod = false
  }, rawget(assert, "__assertionMeta"))
end

function assert.all(list)
  error("NOT IMPLEMENTED")
end

function assert.none(list)
  error("NOT IMPLEMENTED")
end

function error(func)
  return not pcall(func)
end

function assert.unique(list, deep)
  for k,v in pairs(list) do
    for k2, v2 in pairs(list) do
      if k ~= k2 then
        if deep and util.deepcompare(v, v2, true) then
          return false
        else
          if v==v2 then
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
  for k,v in pairs(arg) do
    if prev ~= nil and prev ~= v then
      return false
    end
    prev = v
  end
  return true
end

local function same(...)
  local prev = nil
  for k,v in pairs(arg) do
    if prev ~= nil then
      if type(prev) == 'table' and type(v) == 'table' and not util.deepcompare(prev, v, true) then
        return false
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
assert:register("error", error, "Expected error from function")

assert=setmetatable(assert, assert.__meta)
