local path = require 'pl.path'

local ret = {}
local ok, terralib = not not terralib, terralib --grab the injected global if it exists
if not ok then
  ok, terralib = pcall(require, 'terra') --otherwise, attempt to load terra as a shared library
end

local getTrace = function(filename, info)
  local index = info.traceback:find('\n%s*%[C]')
  info.traceback = info.traceback:sub(1, index)
  return info
end

ret.match = function(busted, filename)
  return ok and path.extension(filename) == '.t'
end

ret.load = function(busted, filename)
  local file, err = terralib.loadfile(filename)
  if not file then
    busted.publish({ 'error', 'file' }, { descriptor = 'file', name = filename }, nil, err, {})
  end
  return file, getTrace
end

return ret
