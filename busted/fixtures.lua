local pl_path = require 'pl.path'
local pl_utils = require 'pl.utils'

local fixtures = {}

-- returns an absolute path to where the current test file is located.
-- @param sub_path [optional] a relative path to, to be appended
-- @return returns the (normalized) absolute path
function fixtures.path(sub_path)
  if type(sub_path) ~= "string" and type(sub_path) ~= "nil" then
    error("bad argument to 'path' expected a string (relative filename) or nil, got: " .. type(sub_path), 2)
  end

  local info = debug.getinfo(1)
  local myname = info.source -- path to this code file

  local path
  local level = 1
  repeat
    -- other functions in this module call this one as well, so traverse up the
    -- stack until we find the first call from outside this module, that's
    -- the file to use as a baseline for our relative search
    level = level + 1
    info = debug.getinfo(level)
    path = info.source
  until path ~= myname

  if path:sub(1,1) == "@" then
    path = path:sub(2, -1)
  end
  path = pl_path.abspath(path) -- based on PWD
  path = pl_path.splitpath(path) -- drop filename, keep path only
  path = pl_path.join(path, sub_path)
  return pl_path.normpath(path, sub_path)
end


-- reads a file relative from the current test file.
-- @param rel_path (string) the relative path to the file
-- @param is_bin (boolean) whether to load the file as a binary file
-- @return returns the file contents or errors on failure
function fixtures.read(rel_path, is_bin)
  if type(rel_path) ~= "string" then
    error("bad argument to 'read' expected a string (relative filename), got: " .. type(rel_path), 2)
  end

  local fname = fixtures.path(rel_path)

  local contents, err = pl_utils.readfile(fname, is_bin)
  if not contents then
    error(("Error reading file '%s': %s"):format(tostring(fname), tostring(err)), 2)
  end

  return contents
end


-- loads (and executes) a Lua-file relative from the current test file.
-- @param rel_path (string) the relative path to the file
-- @return returns the results of the executed file (similar to a module)
function fixtures.load(rel_path)
  if type(rel_path) ~= "string" then
    error("bad argument to 'load' expected a string (relative filename), got: " .. type(rel_path), 2)
  end
  local extension = "lua"
  if not rel_path:match("%."..extension.."$") then
    rel_path = rel_path .. "." .. extension
  end
  local code, err = fixtures.read(rel_path)
  if not code then
    error(("Error loading file '%s': %s"):format(tostring(rel_path), tostring(err)), 2)
  end

  local func, err = (loadstring or load)(code, rel_path)
  if not func then
    error(("Error loading code from '%s': %s"):format(tostring(rel_path), tostring(err)), 2)
  end

  return func()
end


return fixtures
