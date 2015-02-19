local utils = require 'busted.utils'

return function()
  local loadHelper = function(helper, hpath, options, busted)
    local success, err = pcall(function()
      if helper:match('%.lua$') or helper:match('%.moon$') then
        dofile(utils.normpath(hpath))
      else
        require(helper)
      end
    end)

    if not success then
      busted.publish({ 'error', 'helper' }, { descriptor = 'helper', name = helper }, nil, err, {})
    end
  end

  return loadHelper
end
