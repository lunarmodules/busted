local path = require 'pl.path'

return function()
  local loadOutputHandler = function(output, opath, options, busted, defaultOutput)
    local handler

    local success, err = pcall(function()
      if output:match('.lua$') or output:match('.moon$') then
        handler = loadfile(path.normpath(opath))()
      else
        handler = require('busted.outputHandlers.'..output)
      end
    end)

    if not success then
      busted.publish({ 'error', 'output' }, { descriptor = 'output', name = output }, nil, err, {})
      handler = require('busted.outputHandlers.'..defaultOutput)
    end

    return handler(options, busted)
  end

  return loadOutputHandler
end
