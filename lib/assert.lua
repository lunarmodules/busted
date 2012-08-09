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

assert=setmetatable(assert, assert.__meta)

require 'lib/assertions'
