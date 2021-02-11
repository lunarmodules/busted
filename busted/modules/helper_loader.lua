local path = require 'pl.path'
local hasMoon, moonscript = pcall(require, 'moonscript')
local utils = require 'busted.utils'

return function()
  local loadHelper = function(busted, helper, options)
    local old_arg = _G.arg
    local success, err = pcall(function()
      local fn

      utils.copy_interpreter_args(options.arguments)
      _G.arg = options.arguments

      if helper:match('%.lua$') then
        fn = dofile(path.normpath(helper))
      elseif hasMoon and helper:match('%.moon$') then
        fn = moonscript.dofile(path.normpath(helper))
      else
        fn = require(helper)
      end

      if type(fn) == 'function' then
        assert(fn(busted, helper, options))
      end
    end)

    arg = old_arg   --luacheck: ignore

    if not success then
      return nil, err
    end
    return true
  end

  return loadHelper
end
