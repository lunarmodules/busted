local path = require 'pl.path'
local hasMoon, moonscript = pcall(require, 'moonscript')

return function()
  local loadHelper = function(busted, helper, options)
    local old_arg = arg
    local success, err = pcall(function()
      arg = options.arguments
      if helper:match('%.lua$') then
        dofile(path.normpath(helper))
      elseif hasMoon and helper:match('%.moon$') then
        moonscript.dofile(path.normpath(helper))
      else
        require(helper)
      end
    end)

    arg = old_arg

    if not success then
      busted.publish({ 'error', 'helper' }, { descriptor = 'helper', name = helper }, nil, err, {})
    end
  end

  return loadHelper
end
