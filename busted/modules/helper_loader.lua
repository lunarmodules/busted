local utils = require 'busted.utils'
local hasMoon, moonscript = pcall(require, 'moonscript')

return function()
  local loadHelper = function(helper, options, busted)
    local old_arg = arg
    local success, err = pcall(function()
      arg = options.arguments
      if helper:match('%.lua$') then
        dofile(utils.normpath(helper))
      elseif hasMoon and helper:match('%.moon$') then
        moonscript.dofile(utils.normpath(helper))
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
