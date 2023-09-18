local json = require 'dkjson'
local io_write = io.write
local io_flush = io.flush

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()

  handler.suiteEnd = function()
    local error_info = {
      pendings = handler.pendings,
      successes = handler.successes,
      failures = handler.failures,
      errors = handler.errors,
      duration = handler.getDuration()
    }
    local ok, result = pcall(json.encode, error_info)

    if ok then
      io_write(result)
    else
      io_write("Failed to encode test results to json: " .. result)
    end

    io_write("\n")
    io_flush()

    return nil, true
  end

  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)

  return handler
end
