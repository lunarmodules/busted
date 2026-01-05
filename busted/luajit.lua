local function detect_ffi()
  local ok, ffi = pcall(require, "ffi")
  if not ok then
    return { ok = false, err = tostring(ffi) }
  end

  local is_luajit = type(jit) == "table" and type(jit.version) == "string"

  -- If ffi comes from the filesystem, these will usually resolve.
  local lua_file  = package.searchpath("ffi", package.path)
  local c_file    = package.searchpath("ffi", package.cpath)

  -- Another hint: which searcher provides the loader?
  local loader_from
  for i, s in ipairs(package.searchers or package.loaders) do
    local f, extra = s("ffi")
    if type(f) == "function" then
      loader_from = { index = i, extra = extra }
      break
    end
  end

  return {
    ok = true,
    is_luajit = is_luajit,
    jit_version = is_luajit and jit.version or "Not Jit",
    lua_file = lua_file or "nil",
    c_file = c_file or 'nil',
    loader_from = loader_from,
  }
end

--[[
local isJit = (tostring(assert):match('builtin') ~= nil)

if not isJit then
  return function() end
end
]]

local _ffi_info = detect_ffi();
if (not _ffi_info.ok) then
  return function() end
end

-- pre-load the ffi module, such that it becomes part of the environment
-- and Busted will not try to GC and reload it. The ffi is not suited
-- for that and will occasionally segfault if done so.
local ffi = require "ffi"


-- patching assumes;
--  * first parameter to be a unique key to identify repeated calls
--  * only a single return value

local function patch_with_return_value(func_name)
  local original = ffi[func_name]
  local original_store = {}

  ffi[func_name] = function (primary, ...)
    if original_store[primary] then
      return original_store[primary]
    end
    local success, result, err = pcall(original, primary, ...)
    if not success then
      -- hard error was thrown
      error(result, 2)
    end
    if not result then
      -- soft error was returned
      return result, err
    end
    -- it worked, store and return
    original_store[primary] = result
    return result
  end
end

local function patch_without_return_value(func_name)
  local original = ffi[func_name]
  local original_store = {}

  ffi[func_name] = function (primary, ...)
    if original_store[primary] then
      return
    end
    local success, result = pcall(original, primary, ...)
    if not success then
      -- hard error was thrown
      error(result, 2)
    end
    -- store and return
    original_store[primary] = true
    return result
  end
end

return function()
    patch_without_return_value("cdef")
    patch_with_return_value("typeof")
    patch_with_return_value("metatype")
    patch_with_return_value("load")
  end
