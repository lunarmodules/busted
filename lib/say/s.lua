local s = {
  registry = { __g = {}},
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
  __call = function(self, namespace, key, vars)
    local str = ''
    if (not vars and type(key) == 'table') or (not vars and key and not self.registry[namespace]) or (not key and not vars) then
      vars = key
      key = namespace
      namespace = '__g'
    end
    str = self.registry[namespace][key]
    if type(str) ~= 'string' then str = '' end
    return vars and str:format(unpack(vars)) or str
  end,
  __index = function(self, key)
    return self.registry[key]
  end
}

return setmetatable(s, __meta)
