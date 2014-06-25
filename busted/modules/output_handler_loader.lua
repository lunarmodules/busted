local path = require 'pl.path'

return function()
  local loadOutputHandler = function(output, opath, options, busted)
    local handler

    if output:match('.lua$') or output:match('.moon$') then
      handler = loadfile(path.normpath(opath))()
    else
      handler = require('busted.outputHandlers.'..output)
    end

    return handler(options, busted)
  end

  return loadOutputHandler
end
