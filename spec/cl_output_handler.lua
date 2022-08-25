-- supporting testfile; belongs to 'cl_spec.lua'

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()
  local cli = require 'cliargs'
  local args = options.arguments

  cli:set_name('cl_output_handler')
  cli:flag('--time', 'show timestamps')
  cli:option('--time-format=FORMAT', 'format string according to strftime', '!%a %b %d %H:%M:%S %Y')

  local cliArgs, err = cli:parse(args)
  if not cliArgs and err then
    io.stderr:write(string.format('%s: %s\n\n', cli.name, err))
    io.stderr:write(cli.printer.generate_help_and_usage().. '\n')
    os.exit(1)
  end

  handler.testEnd = function(element, parent, status, debug)
    local showTime = cliArgs.time
    local timeFormat = cliArgs['time-format']
    local timestamp = showTime and ('[' .. os.date(timeFormat, 123456) .. '] ') or ''

    print(string.format("%s[%8s] %s", timestamp, status, handler.getFullName(element)))
  end

  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })

  return handler
end
