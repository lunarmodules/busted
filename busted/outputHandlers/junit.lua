local xml = require 'pl.xml'
local socket = require("socket")
local string = require("string")

return function(options, busted)
  local handler = require 'busted.outputHandlers.base'(busted)
  local xml_doc
  local suiteStartTime

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

  local function testStatus(element, parent, message, status, trace)
    local testcase_node = xml.new('testcase', {
      classname = element.trace.short_src .. ':' .. element.trace.currentline,
      name = handler.getFullName(element),
      time = now()
    })
    xml_doc:add_direct_child(testcase_node)

    if status ~= 'success' then
      testcase_node:addtag(status)
      if message then testcase_node:text(message) end
      if trace and trace.traceback then testcase_node:text(trace.traceback) end
      testcase_node:up()
    end
  end

  handler.testEnd = function(element, parent, status)
    xml_doc.attr.tests = xml_doc.attr.tests + 1

    if status == 'success' then
      testStatus(element, parent, nil, 'success')
    elseif status == 'pending' then
      xml_doc.attr.skip = xml_doc.attr.skip + 1
      local formatted = handler.inProgress[tostring(element)] or {}
      testStatus(element, parent, formatted.message, 'skipped', formatted.trace)
    end

    return nil, true
  end

  handler.failureTest = function(element, parent, message, trace)
    xml_doc.attr.failures = xml_doc.attr.failures + 1
    testStatus(element, parent, message, 'failure', trace)
    return nil, true
  end

  handler.errorTest = function(element, parent, message, trace)
    xml_doc.attr.errors = xml_doc.attr.errors + 1
    testStatus(element, parent, message, 'error', trace)
    return nil, true
  end

  handler.error = function(element, parent, message, trace)
    if element.descriptor ~= 'it' then
      xml_doc.attr.errors = xml_doc.attr.errors + 1
      xml_doc:addtag('error')
      xml_doc:text(message)
      if trace and trace.traceback then
        xml_doc:text(trace.traceback)
      end
      xml_doc:up()
    end

    return nil, true
  end

  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'error', 'it' }, handler.errorTest)
  busted.subscribe({ 'failure', 'it' }, handler.failureTest)
  busted.subscribe({ 'error' }, handler.error)
  busted.subscribe({ 'failure' }, handler.error)

  return handler
end
