local ret = {}

local getTrace =  function(filename, info)
  local index = info.traceback:find('\n%s*%[C]')
  info.traceback = info.traceback:sub(1, index)
  return info, false
end

ret.match = function(busted, filename)
  local path, name, ext = filename:match('(.-)([^\\/\\\\]-%.?([^%.\\/]*))$')
  if ext == 'lua' then
    return true
  end
  return false
end


ret.load = function(busted, filename)
  local file, err

  local success, err = pcall(function()
    file, err = loadfile(filename)

    if not file then
      busted.publish({ 'error', 'file' }, filename, nil, nil, err)
    end
  end)

  if not success then
    busted.publish({ 'error', 'file' }, filename, nil, nil, err)
  end

  return file, getTrace
end

return ret
