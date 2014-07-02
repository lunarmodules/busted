local utils = require 'pl.utils'

local ok, moonscript, line_tables, util = pcall(function()
  return require 'moonscript', require 'moonscript.line_tables', require 'moonscript.util'
end)

local _cache = {}

-- find the line number of `pos` chars into fname
local lookup_line = function(fname, pos)
  if not _cache[fname] then
    local f = io.open(fname)
    _cache[fname] = f:read('*a')
    f:close()
  end

  return util.pos_to_line(_cache[fname], pos)
end

local rewrite_linenumber = function(fname, lineno)
  local tbl = line_tables[fname]
  if fname and tbl then
    for i = lineno, 0 ,-1 do
      if tbl[i] then
        return lookup_line(fname, tbl[i])
      end
    end
  end

  return lineno
end

local rewrite_traceback = function(fname, trace)
  local lines = {}
  local j = 0

  local rewrite_one = function(line)
    if line == nil then
      return ''
    end

    local fname, lineno = line:match('[^"]+"([^:]+)".:(%d+):')

    if fname and lineno then
      local new_lineno = rewrite_linenumber(fname, tonumber(lineno))
      if new_lineno then
        line = line:gsub(':' .. lineno .. ':', ':' .. new_lineno .. ':')
      end
    end
    return line
  end

  for line in trace:gmatch('[^\r\n]+') do
    j = j + 1
    lines[j] = rewrite_one(line)
  end

  return table.concat(lines, trace:match('[\r\n]+'))
end

local ret = {}

local getTrace =  function(filename, info)
  local p = require 'pl.pretty'
  local index = info.traceback:find('\n%s*%[C]')
  info.traceback = info.traceback:sub(1, index)

  -- sometimes moonscript gives files like [string "./filename.moon"], so
  -- we'll chop it up to only get the filename.
  info.short_src = info.short_src:match('string "(.+)"') or info.short_src
  info.traceback = rewrite_traceback(filename, info.traceback)
  info.linedefined = rewrite_linenumber(filename, info.linedefined)
  info.currentline = rewrite_linenumber(filename, info.currentline)

  return info
end

local rewriteMessage = function(filename, message)
  local split = utils.split(message, ':', true, 3)

  if #split < 3 then
    return message
  end

  local filename = split[1]
  local line = split[2]
  filename = filename:match('string "(.+)"')

  line = rewrite_linenumber(filename, line)

  return filename .. ':' .. tostring(line)
end

ret.match = function(busted, filename)
  local path, name, ext = filename:match('(.-)([^\\/\\\\]-%.?([^%.\\/]*))$')
  if ok and ext == 'moon' then
    return true
  end
  return false
end


ret.load = function(busted, filename)
  local file

  local success, err = pcall(function()
    file, err = moonscript.loadfile(filename)

    if not file then
      busted.publish({ 'error', 'file' }, filename, nil, nil, err)
    end
  end)

  if not success then
    busted.publish({ 'error', 'file' }, filename, nil, nil, err)
  end

  return file, getTrace, rewriteMessage
end

return ret
