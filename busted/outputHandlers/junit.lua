local xml = require 'pl.xml'
local hostname = assert(io.popen('uname -n')):read('*l')

return function(options, busted)
  local handler = require 'busted.outputHandlers.base'(busted)
  local node

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

  handler.suiteStart = function(name, parent)
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
    local ms = handler.getDuration()
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

  busted.subscribe({ 'test', 'end' }, handler.testEnd)
  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'error', 'file' }, handler.error)

  return handler
end
