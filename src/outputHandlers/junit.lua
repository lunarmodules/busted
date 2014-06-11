local xml = require 'pl.xml'
local hostname = assert(io.popen('uname -n')):read('*l')

return function(options, busted)
  -- options.language, options.deferPrint, options.suppressPending, options.verbose
  local node
  local startTime, endTime
  local handler = {}

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
    node.attr.tests = node.attr.tests + 1

    node:addtag('testcase', {
      classname = element.trace.short_src .. ':' .. element.trace.currentline,
      name = element.name
    })

    if status == 'failure' then
      node.attr.failures = node.attr.failures + 1
    end

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

    node = xml.new('testsuite', {
      tests = 0,
      errors = 0,
      failures = 0,
      skip = 0,
      header = 'Busted Suite',
      hostname = hostname,
      timestamp = os.time()
    })

    return nil, true
  end

  handler.suiteEnd = function(name, parent)
    endTime = os.clock()

    local ms = (endTime - startTime) * 1000
    node.attr.time = ms

    print(xml.tostring(node, '', '\t'))

    return nil, true
  end

  handler.error = function(element, parent, message, trace)
    if status == 'failure' then
      node.attr.errors = node.attr.errors + 1
    end

    node:addtag('failure', {
      message = message
    }):text(trace.traceback):up()

    return nil, true
  end

  return handler
end
