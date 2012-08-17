local json = require("dkjson")

local s = {
  registry = { },

  set_namespace = function(self, namespace)
    self.current_namespace = namespace
  end,

  set = function(self, namespace, key, value)
    if type(value) ~= 'string' then
      value = key
      key = namespace
      namespace = '__g'
    end
    if not self.registry[namespace] then
      self.registry[namespace] = {}
    end
    self.registry[namespace][key] = value
  end
}

local __meta = {
  __call = function(self, key, vars)
    local str = ''

    if (not vars and type(key) == 'table') or (not vars and key and not self.registry[namespace]) or (not key and not vars) then
      vars = key
      key = self.current_namespace
      namespace = '__g'
    end

    if not self.registry[self.current_namespace] then
      self.registry[self.current_namespace] = {}
    end

    str = self.registry[self.current_namespace][key]

    if type(str) ~= 'string' then str = '' end

    local strings = {}

    for i,v in ipairs(vars) do
      local s = v

      if type(v == "table") then
        s = json.encode(v)
      else
        s = tostring(v)
      end

      table.insert(strings, s)
    end

    return #strings > 0 and str:format(unpack(strings)) or str
  end,
  __index = function(self, key)
    return self.registry[key]
  end
}

return setmetatable(s, __meta)
