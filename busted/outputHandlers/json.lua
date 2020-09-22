local json = require 'dkjson'
local io_write = io.write
local io_flush = io.flush

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()

  handler.suiteEnd = function()
    io_write(json.encode({
      pendings = handler.pendings,
      successes = handler.successes,
      failures = handler.failures,
      errors = handler.errors,
      duration = handler.getDuration()
    }))
    io_write("\n")
    io_flush()

    return nil, true
  end

  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)

  return handler
end
