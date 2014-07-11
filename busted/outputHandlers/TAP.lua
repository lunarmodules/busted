local pretty = require 'pl.pretty'
local tablex = require 'pl.tablex'

return function(options, busted)
  local handler = require 'busted.outputHandlers.base'(busted)

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

  handler.suiteEnd = function(name, parent)
    local total = handler.successesCount + handler.errorsCount + handler.failuresCount
    print('1..' .. total)

    local success = 'ok %u - %s'
    local failure = 'not ' .. success
    local counter = 0

    for i,t in pairs(handler.successes) do
      counter = counter + 1
      print(counter .. ' ' .. handler.format(t).name)
    end

    for i,t in pairs(handler.failures) do
      counter = counter + 1
      local message = t.message

      if message == nil then
        message = 'Nil error'
      elseif type(message) ~= 'string' then
        message = pretty.write(message)
      end

      print(counter .. ' ' .. handler.format(t).name)
      print('# ' .. t.trace.short_src .. ' @ ' .. t.trace.currentline)
      print('# Failure message: ' .. message:gsub('\n', '\n# ' ))
    end

    return nil, true
  end

  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)

  return handler
end
