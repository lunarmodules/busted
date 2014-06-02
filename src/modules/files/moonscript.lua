local moonscript = require 'moonscript'
local line_tables = require 'moonscript.line_tables'
local util = require 'moonscript.util'

local _cache = {}

-- find the line number of `pos` chars into fname
local lookup_line = function(fname, pos)
  if not _cache[fname] then
    local f = io.open(fname)
    _cache[fname] = f:read("*a")
    f:close()
  end
  return util.pos_to_line(_cache[fname], pos)
end

local rewrite_linenumber = function(fname, lineno)
  local tbl = line_tables[fname]
  if fname and tbl then
    for i = lineno,0,-1 do
      if tbl[i] then
        return lookup_line(fname, tbl[i])
      end
    end
  end
end

local rewrite_traceback = function(trace)
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
  info.traceback = rewrite_traceback(info.traceback)
  info.linedefined = rewrite_linenumber(filename, info.currentline)

  -- make short_src consistent with lua
  info.short_src = info.source

  return info
end

ret.match = function(busted, filename)
  local path, name, ext = filename:match('(.-)([^\\/\\\\]-%.?([^%.\\/]*))$')
  if ext == 'moon' then
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

  return file, getTrace
end

return ret
