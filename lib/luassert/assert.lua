local __assertion_meta = {
  __call = function(self, ...)
    local state = self.state
    local val = self.callback(state, ...)
    local data_type = type(val)
    if data_type == "boolean" then
      if val ~= state.mod then
        error(self.message or "assertion failed!")
      else
        return state
      end
    end
    return val
  end
}

local __state_meta = {

  __call = function(self, payload, callback)
    self.payload = payload or rawget(self, "payload")
    if callback then callback(self) end
    return self
  end,

  __index = function(self, key)
    if rawget(assert, "modifier")[key] then
      rawget(assert, "modifier")[key].state = self
      return self(nil,
      rawget(assert, "modifier")[key]
      )
    else
      rawget(assert, "assertion")[key].state = self
      return rawget(assert, "assertion")[key]
    end
  end

}

local obj = {
  -- list of registered assertions
  assertion = {},

  state = function() return setmetatable({mod=true, payload=nil}, __state_meta) end,

  -- list of registered modifiers
  modifier = {},

  -- registers a function in namespace
  register = function(self, namespace, name, callback, message)
    local lowername = name:lower()
    if not assert[namespace] then
      assert[namespace] = {}
    end
    assert[namespace][lowername] = setmetatable({callback = callback, name = lowername, message=message}, __assertion_meta)
  end

}

local __meta = {

  __call = function(self, bool, message)
    if not bool then
      error(message or "assertion failed!")
    end
    return bool
  end,

  __index = function(self, key) return self.state()[key] end

}
return setmetatable(obj, __meta)
