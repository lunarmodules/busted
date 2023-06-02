local s = require 'say'
local pretty = require 'pl.pretty'
local term = require 'term'
local luassert = require 'luassert'
local io = io
local type = type
local string_format = string.format
local string_gsub = string.gsub
local io_write = io.write
local io_flush = io.flush
local pairs = pairs
local colors

local isatty = io.type(io.stdout) == 'file' and term.isatty(io.stdout)

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()
  local cli = require 'cliargs'
  local args = options.arguments

  cli:set_name('utfTerminal output handler')
  cli:flag('--color', 'force use of color')
  cli:flag('--plain', 'force use of no color')

  local cliArgs, err = cli:parse(args)
  if not cliArgs and err then
    io.stderr:write(string.format('%s: %s\n\n', cli.name, err))
    io.stderr:write(cli.printer.generate_help_and_usage().. '\n')
    os.exit(1)
  end

  if cliArgs.plain then
    colors = setmetatable({}, {__index = function() return function(s) return s end end})
    luassert:set_parameter("TableErrorHighlightColor", "none")

  elseif cliArgs.color then
    colors = require 'term.colors'
    luassert:set_parameter("TableErrorHighlightColor", "red")

  else
    if package.config:sub(1,1) == '\\' and not os.getenv("ANSICON") or not isatty then
      -- Disable colors on Windows.
      colors = setmetatable({}, {__index = function() return function(s) return s end end})
      luassert:set_parameter("TableErrorHighlightColor", "none")
    else
      colors = require 'term.colors'
      luassert:set_parameter("TableErrorHighlightColor", "red")
    end
  end

  local successDot = colors.green('\226\151\143') -- '\226\151\143' = '●' = utf8.char(9679)
  local failureDot = colors.red('\226\151\188') -- '\226\151\188' = '◼' = utf8.char(9724)
  local errorDot   = colors.magenta('\226\156\177') -- '\226\156\177' = '✱' = utf8.char(10033)
  local pendingDot = colors.yellow('\226\151\140') -- '\226\151\140' = '◌' = utf8.char(9676)

  local pendingDescription = function(pending)
    local name = pending.name

    -- '\226\134\146' = '→' = utf8.char('8594')
    local string = colors.yellow(s('output.pending')) .. ' \226\134\146 ' ..
      colors.cyan(pending.trace.short_src) .. ' @ ' ..
      colors.cyan(pending.trace.currentline)  ..
      '\n' .. colors.bright(name)

    if type(pending.message) == 'string' then
      string = string .. '\n' .. pending.message
    elseif pending.message ~= nil then
      string = string .. '\n' .. pretty.write(pending.message)
    end

    return string
  end

  local failureMessage = function(failure)
    local string = failure.randomseed and ('Random seed: ' .. failure.randomseed .. '\n') or ''
    if type(failure.message) == 'string' then
      string = string .. failure.message
    elseif failure.message == nil then
      string = string .. 'Nil error'
    else
      string = string .. pretty.write(failure.message)
    end

    return string
  end

  local failureDescription = function(failure, isError)
    -- '\226\134\146' = '→' = utf8.char(8594)
    local string = colors.red(s('output.failure')) .. ' \226\134\146 '
    if isError then
      string = colors.magenta(s('output.error')) .. ' \226\134\146 '
    end

    if not failure.element.trace or not failure.element.trace.short_src then
      string = string ..
        colors.cyan(failureMessage(failure)) .. '\n' ..
        colors.bright(failure.name)
    else
      string = string ..
        colors.cyan(failure.element.trace.short_src) .. ' @ ' ..
        colors.cyan(failure.element.trace.currentline) .. '\n' ..
        colors.bright(failure.name) .. '\n' ..
        failureMessage(failure)
    end

    if options.verbose and failure.trace and failure.trace.traceback then
      string = string .. '\n' .. failure.trace.traceback
    end

    return string
  end

  local statusString = function()
    local successString = s('output.success_plural')
    local failureString = s('output.failure_plural')
    local pendingString = s('output.pending_plural')
    local errorString = s('output.error_plural')

    local sec = handler.getDuration()
    local successes = handler.successesCount
    local pendings = handler.pendingsCount
    local failures = handler.failuresCount
    local errors = handler.errorsCount

    if successes == 0 then
      successString = s('output.success_zero')
    elseif successes == 1 then
      successString = s('output.success_single')
    end

    if failures == 0 then
      failureString = s('output.failure_zero')
    elseif failures == 1 then
      failureString = s('output.failure_single')
    end

    if pendings == 0 then
      pendingString = s('output.pending_zero')
    elseif pendings == 1 then
      pendingString = s('output.pending_single')
    end

    if errors == 0 then
      errorString = s('output.error_zero')
    elseif errors == 1 then
      errorString = s('output.error_single')
    end

    local formattedTime = string_gsub(string_format('%.6f', sec), '([0-9])0+$', '%1')

    return colors.green(successes) .. ' ' .. successString .. ' / ' ..
      colors.red(failures) .. ' ' .. failureString .. ' / ' ..
      colors.magenta(errors) .. ' ' .. errorString .. ' / ' ..
      colors.yellow(pendings) .. ' ' .. pendingString .. ' : ' ..
      colors.bright(formattedTime) .. ' ' .. s('output.seconds')
  end

  handler.testEnd = function(element, parent, status, debug)
    if not options.deferPrint then
      local string = successDot

      if status == 'pending' then
        string = pendingDot
      elseif status == 'failure' then
        string = failureDot
      elseif status == 'error' then
        string = errorDot
      end

      io_write(string)
      io_flush()
    end

    return nil, true
  end

  handler.suiteStart = function(suite, count, total)
    local runString = (total > 1 and '\nRepeating all tests (run %u of %u) . . .\n\n' or '')
    io_write(string_format(runString, count, total))
    io_flush()

    return nil, true
  end

  handler.suiteEnd = function()
    io_write('\n')
    io_write(statusString()..'\n')

    for i, pending in pairs(handler.pendings) do
      io_write('\n')
      io_write(pendingDescription(pending)..'\n')
    end

    for i, err in pairs(handler.failures) do
      io_write('\n')
      io_write(failureDescription(err)..'\n')
    end

    for i, err in pairs(handler.errors) do
      io_write('\n')
      io_write(failureDescription(err, true)..'\n')
    end

    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    io_write(errorDot)
    io_flush()

    return nil, true
  end

  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'error', 'file' }, handler.error)
  busted.subscribe({ 'failure', 'file' }, handler.error)
  busted.subscribe({ 'error', 'describe' }, handler.error)
  busted.subscribe({ 'failure', 'describe' }, handler.error)

  return handler
end
