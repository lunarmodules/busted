local pretty = require 'pl.pretty'
local json = require 'dkjson'

return function(options, busted)
  -- options.language, options.deferPrint, options.suppressPending, options.verbose
  local handler = {}
  local tests = {}

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

  handler.testStart = function(name, parent)
    return nil, true
  end

  handler.testEnd = function(element, parent, status)
    table.insert(tests, {
      name = getFullName(element),
      status = status,
      trace = element.trace
    })

    print(json.encode(tests[#tests]))

    return nil, true
  end

  handler.fileStart = function(name, parent)
    return nil, true
  end

  handler.fileEnd = function(name, parent)
    return nil, true
  end

  handler.suiteStart = function(name, parent)
    return nil, true
  end

  handler.suiteEnd = function(name, parent)
    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    table.insert(tests, {
      elementTrace = element.trace or debug,
      name = getFullName(element),
      message = message,
      success = false
    })

    return nil, true
  end

  return handler
end
