return {
  getfenv = getfenv or function(f)
    f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
    local name, value
    local up = 0

    repeat
      up = up + 1
      name, value = debug.getupvalue(f, up)
    until name == '_ENV' or name == nil

    return (name and value or _G)
  end,

  setfenv = setfenv or function(f, t)
    f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
    local name
    local up = 0

    repeat
      up = up + 1
      name = debug.getupvalue(f, up)
    until name == '_ENV' or name == nil

    if name then
      debug.upvaluejoin(f, up, function() return t end, 1)
    end
  end
}
