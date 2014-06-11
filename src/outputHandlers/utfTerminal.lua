local ansicolors = require 'ansicolors'
local s = require 'say'
local pretty = require 'pl.pretty'

require('busted.languages.en')

return function(options)
  -- options.language, options.deferPrint, options.suppressPending, options.verbose
  local handler = { }
  local tests = 0
  local successes = 0
  local failures = 0
  local pendings = 0

  local successString =  ansicolors('%{green}●')
  local failureString =  ansicolors('%{red}●')
  local pendingString = ansicolors('%{yellow}●')
  local runningString = ansicolors('%{blue}○')

  local failureInfos = { }
  local pendingInfos = { }

  local startTime, endTime

  local pendingDescription = function(pending)
    local name = pending.name or ''

    local string = '\n\n' .. ansicolors('%{yellow}' .. s('output.pending')) .. ' → ' ..
      ansicolors('%{cyan}' .. pending.elementTrace.short_src) .. ' @ ' ..
      ansicolors('%{cyan}' .. pending.elementTrace.currentline)  ..
      '\n' .. ansicolors('%{bright}' .. name)

    return string
  end

  local failureDescription = function(failure)
    local string =  ansicolors('%{red}' .. s('output.failure')) .. ' → ' ..
    ansicolors('%{cyan}' .. failure.elementTrace.short_src) .. ' @ ' ..
    ansicolors('%{cyan}' .. failure.elementTrace.currentline) ..
    '\n' .. ansicolors('%{bright}' .. (failure.name or failure.descriptor)) .. '\n'

    if type(failure.message) == 'string' then
      string = string .. failure.message
    elseif failure.message == nil then
      string = string .. 'Nil error'
    else
      string = string .. pretty.write(failure.message)
    end

    if options.verbose then
      string = string .. failure.debug.traceback
    end

    return string
  end

  local statusString = function(successes, failures, pendings, ms)
    local successString = s('output.success_plural')
    local failureString = s('output.failure_plural')
    local pendingString = s('output.pending_plural')

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

    local formattedTime = ('%.6f'):format(ms):gsub('([0-9])0+$', '%1')

    return ansicolors('%{green}' .. successes) .. ' ' .. successString .. ' / ' ..
      ansicolors('%{red}' .. failures) .. ' ' .. failureString .. ' / ' ..
      ansicolors('%{yellow}' .. pendings) .. ' ' .. pendingString .. ' : ' ..
      ansicolors('%{bright}' .. formattedTime) .. ' ' .. s('output.seconds')
  end

  handler.testStart = function(name, parent)
    tests = tests + 1

    if not options.deferPrint then
      io.write(runningString)
    end
  end

  handler.testEnd = function(name, parent, status)
    if not options.deferPrint then
      io.write('\08')
    end

    local string = successString

    if status then
      successes = successes + 1
    else
      string = failureString
      failures = failures + 1
    end

    if not options.deferPrint then
      io.write(string)
      io.flush()
    end
  end

  handler.pending = function(element, parent, message, debug)
    if not options.suppressPending and not options.deferPrint then
      pendings = pendings + 1
      io.write(pendingString)
      table.insert(pendingInfos, { name = element.name, elementTrace = element.trace, debug = debug })
    end
  end

  handler.fileStart = function(name, parent)
  end

  handler.fileEnd = function(name, parent)
  end

  handler.suiteStart = function(name, parent)
    startTime = os.clock()
  end

  handler.suiteEnd = function(name, parent)
    endTime = os.clock()
    -- print an extra newline of defer print
    if not options.deferPrint then
      print('')
    end

    print(statusString(successes, failures, pendings, endTime - startTime, {}))

    for i, pending in pairs(pendingInfos) do
      print(pendingDescription(pending))
    end

    if #failureInfos > 0 then
      print('')
      print(ansicolors('%{red}Errors:'))
    end

    for i, err in pairs(failureInfos) do
      print(failureDescription(err))
    end

  end

  handler.error = function(element, parent, message, debug)
    table.insert(failureInfos, {
      elementTrace = element.trace,
      name = element.name,
      descriptor = element.descriptor,
      message = message,
      debug = debug
    })
  end

  return handler
end
