assert = {
  -- mod values invert boolean expressions. Used to implement
  -- the not function
  mod = true,

  -- list of registered assertions
  assertions = {},

  -- list of registered builtins
  raw = {},

  -- Assertion meta table, contains index meta method which
  -- is used to find an assertion table and return it
  -- generically
  __assertionMeta = {
    __index = function(table, key)
      local keylower = key:lower()
      assert.assertions[keylower].mod = table.mod
      return assert.assertions[keylower]
    end
  },

  -- Caller meta table, contains the call meta method used to
  -- call a registered assertion function by name
  __callerMeta = {
    __call = function(assertion, ...)
      if assert.assertions[assertion.name].assertion(...) ~= assertion.mod then
        error(assertion.errormessage)
      end

      return true
    end
  },

  -- main assert meta table, like the other meta tables it is used to
  -- generically call assertion functions. Contains call and index meta
  -- methods that perform similar but not identical functions to the
  -- above
  __meta = {
    -- this call method mimics the behavior of the lua default assert 
    -- function
    __call = function(table, bool, message)
      if not bool then
        error(message or "assertion failed!")
      end

      return true
    end,

    __index = function(table, key)
      local keylower = key:lower()
      if table.assertions[keylower] then
        table.assertions[keylower].mod = table.mod
        return table.assertions[keylower]
      else
        if table.raw[keylower] ~= nil then
          if type(table.raw[keylower]) == 'function' then
            return table.raw[keylower]()
          else
            return table.raw[keylower]
          end
        else
          return rawget(table, keylower)
        end
      end
    end
  }
}

-- raw functions, these are the builtins that manipulate the results or uses of the registered assertions
function assert.raw.is() return setmetatable({mod = true}, assert.__assertionMeta) end
function assert.raw.are() return assert.raw.is() end

function assert.raw.is_not() return setmetatable({mod = false}, assert.__assertionMeta) end
function assert.raw.are_not() return assert.raw.is_not() end

function assert.raw.all(list) error("NOT IMPLEMENTED")end
function assert.raw.none(list) error("NOT IMPLEMENTED")end

-- registers an assertion function
function assert:register(name, assertion, errormessage)
  local lowername = name:lower()
  self.assertions[lowername] = setmetatable({mod=false, assertion = assertion, name = lowername, errormessage=errormessage}, assert.__callerMeta)
end

-- and finally, we return our assert replacement
assert=setmetatable(assert, assert.__meta)

-- oh yeah, and we register our default assertions
require 'luassert.assertions'
