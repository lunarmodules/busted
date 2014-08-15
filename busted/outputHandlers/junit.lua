local xml = require 'pl.xml'
local socket = require("socket")
local string = require("string")

return function(options, busted)
  local handler = require 'busted.outputHandlers.base'(busted)
  local xml_doc
  local suiteStartTime, suiteEndTime

  handler.suiteStart = function()
    suiteStartTime = socket.gettime()
    xml_doc = xml.new('testsuite', {
      tests = 0,
      errors = 0,
      failures = 0,
      skip = 0,
    })

    return nil, true
  end

  local function now()
    return string.format("%.2f", (socket.gettime() - suiteStartTime))
  end

  handler.suiteEnd = function()
    xml_doc.attr.time = now()

    print(xml.tostring(xml_doc, '', '\t', nil, false))

    return nil, true
  end

  handler.testEnd = function(element, parent, status)
    xml_doc.attr.tests = xml_doc.attr.tests + 1

    local testcase_node = xml.new('testcase', {
      classname = element.trace.short_src .. ':' .. element.trace.currentline,
      name = handler.getFullName(element),
      time = now()
    })
    xml_doc:add_direct_child(testcase_node)

    if status == 'failure' then
      xml_doc.attr.failures = xml_doc.attr.failures + 1
      testcase_node:addtag('failure')
      testcase_node:text(element.trace.traceback)
      testcase_node:up()
    end

    return nil, true
  end

  handler.errorFile = function()
    if status == 'failure' then
      xml_doc.attr.errors = xml_doc.attr.errors + 1
    end

    xml_doc:addtag('failure', {}):text(trace.traceback):up()

    return nil, true
  end

  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'error', 'file' }, handler.errorFile)

  return handler
end
