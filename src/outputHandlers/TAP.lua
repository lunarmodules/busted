local pretty = require 'pl.pretty'

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
  end

  handler.testEnd = function(element, parent, status)
    if status then
      table.insert(tests, {
        name = getFullName(element),
        success = true
      })
    end
  end

  handler.fileStart = function(name, parent)
  end

  handler.fileEnd = function(name, parent)
  end

  handler.suiteStart = function(name, parent)
  end

  handler.suiteEnd = function(name, parent)
    print('1..' .. #tests)

    local success = 'ok %u - %s'
    local failure = 'not ' .. success

    for i,t in pairs(tests) do
      if t.success then
        print(success:format(i, t.name))
      else
        local message = t.message

        if message == nil then
          message = 'Nil error'
        elseif type(message) ~= 'string' then
          message = pretty.write(message)
        end

        print(failure:format(i, t.name))
        print('# ' .. t.elementTrace.short_src .. ' @ ' .. t.elementTrace.currentline)
        print('# ' .. message:gsub('\n', '\n# ' ))
      end
    end
  end

  handler.error = function(element, parent, message, debug)
    table.insert(tests, {
      elementTrace = element.trace,
      name = getFullName(element),
      message = message,
      success = false
    })
  end

  return handler
end
