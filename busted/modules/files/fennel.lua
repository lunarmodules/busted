-- NOTE: the traceback of `pending` and `error` is broken, and there does not
-- seem to be anything we can do about it.  The Moonscript loader has the same
-- problem.


local path = require 'pl.path'
local ok, fennel = pcall(require, 'fennel')

local MESSAGE_PATTERN = '^([^\n]-):(%d+): (.*)'
local MESSAGE_TEMPLATE = '%s:%d: %s'
local source_maps = {}

local ret = {}

-- A Fennel variant of the standard Lua loadstring function; registers a source
-- map for the given chunk as a side effect.
local function loadstring_(str, chunk_name)
  local options = {filename = chunk_name:sub(2)}
  local success, lua, src_map = pcall(fennel.compileString, str, options)
  if not success then
    return nil, lua, nil
  end
  -- NOTE: `loadstring` was deprecated in favour of a more general `load` in
  -- Lua 5.2
  local thunk, err = (loadstring or load)(lua, chunk_name)
  return thunk, err, src_map
end

-- A Fennel variant of the standard Lua loadfile function
local function loadfile_(fname)
  local file, err = io.open(fname)
  if not (file) then
    return nil, err
  end
  local text = assert(file:read("*a"))
  file:close()
  return loadstring_(text, '@' .. tostring(fname))
end

-- Sometimes Fennel gives files like [string "./filename.fnl"], so we'll chop
-- it up to only get the filename.
local rewrite_filename = function(filename)
  return filename:match('string "(.+)"') or filename
end

-- Maps a Lua line number to the corresponding Fennel line number using a
-- previously stored source map.
local rewrite_linenumber = function(fname, lineno)
  local src_map = source_maps['@' .. fname]
  if not fname or not src_map then return lineno end

  local entry = src_map[lineno]
  if not entry then return lineno end

  -- Assume that all lines of a Lua file are stored in the same Fennel file;
  -- the format of all entries is {file_name, line_number}
  return entry[2]
end

local getTrace = function(filename, info)
  -- NOTE: `info` is the result of `debug.getinfo(level, 'Sl')`, enriched with
  -- `traceback` and `message`. The `traceback` is result of
  -- `debug.traceback('', level)`

  local index = info.traceback:find('\n%s*%[C]')
  info.traceback = info.traceback:sub(1, index)

  info.short_src = rewrite_filename(info.short_src)
  info.linedefined = rewrite_linenumber(filename, info.linedefined)
  info.currentline = rewrite_linenumber(filename, info.currentline)

  return info
end

local rewriteMessage = function(filename, message)
  local fname, lineno, msg = message:match(MESSAGE_PATTERN)
  if not fname then
    return message
  end

  fname = rewrite_filename(fname)
  lineno = rewrite_linenumber(fname, tonumber(lineno))

  return MESSAGE_TEMPLATE:format(fname, tostring(lineno), msg)
end

ret.match = function(busted, filename)
  local result = ok and path.extension(filename) == '.fnl'
  return result
end

ret.load = function(busted, filename)
  local file, err, src_map = loadfile_(filename)
  if not file then
    busted.publish({'error', 'file'}, {descriptor = 'file', name = filename}, nil, err, {})
  else
    source_maps[assert(src_map).key] = src_map
  end
  return file, getTrace, rewriteMessage
end

return ret
