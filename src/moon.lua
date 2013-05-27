local success, ms = pcall(function() return require("moonscript") end)

local is_moon = function(fname)
  return fname:find(".moon", #fname-6, true) and true or false
end

if not success then
  return {
    has_moon = false,
    is_moon = is_moon,
    loadfile = loadfile,
    rewrite_traceback = function(err, trace) return err, trace end
  }
end

local util = require("moonscript.util")
local line_tables = require("moonscript.line_tables")
local table = require("table")

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

local rewrite_traceback = function(err, trace)
  local lines = {}
  local j = 0

  local rewrite_one = function(line)
    if line == nil then
      return ""
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

  for line in trace:gmatch("[^\r\n]+") do
    j = j + 1
    lines[j] = rewrite_one(line)
  end

  return rewrite_one(err), table.concat(lines, trace:match("[\r\n]+"))
end

return {
    loadfile=ms.loadfile,
    has_moon=true,
    is_moon=is_moon,
    rewrite_linenumber=rewrite_linenumber,
    rewrite_traceback=rewrite_traceback
}
