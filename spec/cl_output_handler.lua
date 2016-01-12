-- supporting testfile; belongs to 'cl_spec.lua'

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()
  local cli = require 'cliargs'
  local args = options.arguments

  cli:set_name('cl_output_handler')
  cli:flag('--time', 'show timestamps')
  cli:option('--time-format=FORMAT', 'format string according to strftime', '!%a %b %d %H:%M:%S %Y')

  local cliArgs = cli:parse(args)

  handler.testEnd = function(element, parent, status, debug)
    local showTime = cliArgs.time
    local timeFormat = cliArgs['time-format']
    local timestamp = showTime and ('[' .. os.date(timeFormat, 123456) .. '] ') or ''

    print(string.format("%s[%8s] %s", timestamp, status, handler.getFullName(element)))
  end

  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })

  return handler
end
