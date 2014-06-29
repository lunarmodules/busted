local s = require 'say'
local pretty = require 'pl.pretty'

return function(options, busted)
  local language = require('busted.languages.' .. options.language)
  -- options.language, options.deferPrint, options.suppressPending, options.verbose
  local handler = { }
  local tests = 0
  local successes = 0
  local failures = 0
  local pendings = 0

  local successString =  '+'
  local failureString =  '-'
  local pendingString = '.'

  local failureInfos = { }
  local pendingInfos = { }

  local startTime, endTime

  local getFullName = function(context)
    local parent = context.parent
    local names = { (context.name or context.descriptor) }

    while parent and (parent.name or parent.descriptor) and
          parent.descriptor ~= 'file' do

      current_context = context.parent
      table.insert(names, 1, parent.name or parent.descriptor)
      parent = busted.context.parent(parent)
    end

    return table.concat(names, ' ')
  end

  local pendingDescription = function(pending)
    local name = getFullName(pending)

    local string = '\n\n' .. s('output.pending') .. ': ' ..
      pending.elementTrace.short_src .. ' @ ' ..
      pending.elementTrace.currentline  ..
      '\n' .. name

    return string
  end

  local failureDescription = function(failure)
    local string =  s('output.failure') .. ': '

    if failure.elementTrace then
      string = string .. failure.elementTrace.short_src .. ' @ ' ..
                failure.elementTrace.currentline
    else
      string = string .. failure.debug
    end

    string = string .. '\n' .. getFullName(failure) .. '\n\n'

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

    return successes .. ' ' .. successString .. ' / ' ..
      failures .. ' ' .. failureString .. ' / ' ..
      pendings .. ' ' .. pendingString .. ' : ' ..
      formattedTime .. ' ' .. s('output.seconds')
  end

  handler.testStart = function(name, parent)
    tests = tests + 1

    return nil, true
  end

  handler.testEnd = function(element, parent, status, debug)
    local string = successString

    if status == 'success' then
      successes = successes + 1
    elseif status == 'pending' then
      if not options.suppressPending then
        string = pendingString
        pendings = pendings + 1
        table.insert(pendingInfos, {
          name = element.name,
          elementTrace = element.trace,
          parent = parent
        })
      end
    elseif status == 'failure' then
      string = failureString
      failures = failures + 1
    end

    if not options.deferPrint then
      io.write(string)
      io.flush()
    end

    return nil, true
  end

  handler.pending = function(element, parent, message, debug)
    return nil, true
  end

  handler.fileStart = function(name, parent)
    return nil, true
  end

  handler.fileEnd = function(name, parent)
    return nil, true
  end

  handler.suiteStart = function(name, parent)
    startTime = os.clock()
    return nil, true
  end

  handler.suiteEnd = function(name, parent)
    endTime = os.clock()
    -- print an extra newline of defer print
    if not options.deferPrint then
      print('')
    end

    print(statusString(successes, failures, pendings, endTime - startTime, {}))

    if #pendingInfos > 0 then print('') end
    for i, pending in pairs(pendingInfos) do
      print(pendingDescription(pending))
    end

    if #failureInfos > 0 then print('') end
    for i, err in pairs(failureInfos) do
      print(failureDescription(err))
    end

    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    table.insert(failureInfos, {
      elementTrace = element.trace,
      name = element.name,
      descriptor = element.descriptor,
      message = message,
      debug = debug,
      parent = parent
    })

    return nil, true
  end

  return handler
end
