local json = require("dkjson")

local s = {
  registry = { },

  set_namespace = function(self, namespace)
    self.current_namespace = namespace
  end,

  set = function(self, key, value)
    if not self.registry[self.current_namespace] then
      self.registry[self.current_namespace] = {}
    end

    self.registry[self.current_namespace][key] = value
  end
}

local __meta = {
  __call = function(self, key, vars)
    local str = ''

    if not self.registry[self.current_namespace] then
      self.registry[self.current_namespace] = {}
    end

    if not vars then
      vars = {}
    end

    str = self.registry[self.current_namespace][key]

    if type(str) ~= 'string' then str = '' end

    local strings = {}

    for i,v in ipairs(vars) do
      local s = v

      if type(v) == "table" then
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
