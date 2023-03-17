local isJit = (tostring(assert):match('builtin') ~= nil)

if not isJit then
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
