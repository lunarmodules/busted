local pretty = require 'pl.pretty'
local tablex = require 'pl.tablex'
local json = require 'dkjson'

return function(options, busted)
  local handler = require 'busted.outputHandlers.base'(busted)
  handler.suiteEnd = function(element, parent, status)
    print(json.encode({
      pendings = handler.pendings,
      successes = handler.successes,
      failures = handler.failures,
      errors = handler.errors,
      duration = handler.getDuration()
    }))

    return nil, true
  end

  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)

  return handler
end
