local xml = require 'pl.xml'
local string = require("string")
local io = io
local type = type
local string_format = string.format
local io_open = io.open
local io_write = io.write
local io_flush = io.flush
local os_date = os.date
local table_insert = table.insert
local table_remove = table.remove

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()
  local top = {
    start_tick = busted.monotime(),
    xml_doc = xml.new('testsuites', {
      tests = 0,
      errors = 0,
      failures = 0,
      skip = 0,
    })
  }
  local output_file_name
  local enable_split_output_xml
  local stack = {}
  local testcase_node
  if 'table' == type(options.arguments) then
    if options.arguments[1] == "true" then
      enable_split_output_xml = true
    else
      -- will output to the sepcific xml file
      output_file_name = options.arguments[1]
    end
  end

  handler.suiteStart = function(suite, count, total)
    local suite_xml = {
      start_tick = suite.starttick,
      xml_doc = xml.new('testsuite', {
        name = 'Run ' .. count .. ' of ' .. total,
        tests = 0,
        errors = 0,
        failures = 0,
        skip = 0,
        timestamp = os_date('!%Y-%m-%dT%H:%M:%S'),
      })
    }
    top.xml_doc:add_direct_child(suite_xml.xml_doc)
    table_insert(stack, top)
    top = suite_xml

    return nil, true
  end

  local function formatDuration(duration)
    return string_format("%.2f", duration)
  end

  local function elapsed(start_time)
    return formatDuration(busted.monotime() - start_time)
  end

  handler.suiteEnd = function(suite, count, total)
    local suite_xml = top
    suite_xml.xml_doc.attr.time = formatDuration(suite.duration)

    top = table_remove(stack)
    top.xml_doc.attr.tests = top.xml_doc.attr.tests + suite_xml.xml_doc.attr.tests
    top.xml_doc.attr.errors = top.xml_doc.attr.errors + suite_xml.xml_doc.attr.errors
    top.xml_doc.attr.failures = top.xml_doc.attr.failures + suite_xml.xml_doc.attr.failures
    top.xml_doc.attr.skip = top.xml_doc.attr.skip + suite_xml.xml_doc.attr.skip

    top.xml_doc.attr.time = elapsed(top.start_tick)

    if enable_split_output_xml ~= nil then
      local output_string = xml.tostring(top.xml_doc, '', '\t', nil, false)
      local test_suit_file = suite['file']

      local write_file
      if test_suit_file ~= nil then
        write_file = string.gsub(test_suit_file[1].name, "%.[^.]+$", ".xml")
      else
        write_file = "no_match_cases.xml"
      end

      local file = io_open(write_file, 'w+b' )
      if file then
        file:write(output_string)
        file:write('\n')
        file:close()
      end
    end

    return nil, true
  end

  handler.exit = function()
    top.xml_doc.attr.time = elapsed(top.start_tick)
    local output_string = xml.tostring(top.xml_doc, '', '\t', nil, false)
    local file
    if 'string' == type(output_file_name) then
      file = io_open(output_file_name, 'w+b' )
    end
    if file then
      file:write(output_string)
      file:write('\n')
      file:close()
    else
      io_write(output_string)
      io_write("\n")
      io_flush()
    end
    return nil, true
  end

  local function testStatus(element, parent, message, status, trace)
    if status ~= 'success' then
      testcase_node:addtag(status)
      if status ~= 'pending' and parent and parent.randomseed then
        testcase_node:text('Random seed: ' .. parent.randomseed .. '\n')
      end
      if message then testcase_node:text(message) end
      if trace and trace.traceback then testcase_node:text(trace.traceback) end
      testcase_node:up()
    end
  end

  local function get_package_and_file(path)
    local package, file

    if string.match(path, "/") or string.match(path, "\\") then
      -- Compatible with Windows platform
      package, file = path:match("(.-)[\\/]+([^\\/]+)$")
    else
      package, file = "", path
    end

    return package, file
  end

  handler.testStart = function(element, parent)
    local test_case_full_name = handler.getFullName(element)
    local package, file_name = get_package_and_file(element.trace.source)

    -- Jenkins CI Junit Plugin use the last one . to distinguish between package name and class name.
    local class_name = string.gsub(file_name, "%.", "_")

    if package and package ~= "" then
      if package:find("^@") then
        package = string.sub(package, 2)
      end
      class_name = package .. "." .. class_name .. ":" .. element.trace.currentline
    else
      class_name = class_name .. ":" .. element.trace.currentline
    end

    testcase_node = xml.new('testcase', {
      -- junit report uses package names and class names to structurally display result.
      classname = class_name,
      name = test_case_full_name
    })
    top.xml_doc:add_direct_child(testcase_node)

    return nil, true
  end

  handler.testEnd = function(element, parent, status)
    top.xml_doc.attr.tests = top.xml_doc.attr.tests + 1
    testcase_node:set_attrib("time", formatDuration(element.duration))

    if status == 'success' then
      testStatus(element, parent, nil, 'success')
    elseif status == 'pending' then
      top.xml_doc.attr.skip = top.xml_doc.attr.skip + 1
      local formatted = handler.pendings[#handler.pendings]
      local trace = element.trace ~= formatted.trace and formatted.trace
      testStatus(element, parent, formatted.message, 'skipped', trace)
    end

    return nil, true
  end

  handler.failureTest = function(element, parent, message, trace)
    top.xml_doc.attr.failures = top.xml_doc.attr.failures + 1
    testStatus(element, parent, message, 'failure', trace)
    return nil, true
  end

  handler.errorTest = function(element, parent, message, trace)
    top.xml_doc.attr.errors = top.xml_doc.attr.errors + 1
    testStatus(element, parent, message, 'error', trace)
    return nil, true
  end

  handler.error = function(element, parent, message, trace)
    if element.descriptor ~= 'it' then
      top.xml_doc.attr.errors = top.xml_doc.attr.errors + 1
      top.xml_doc:addtag('error')
      top.xml_doc:text(message)
      if trace and trace.traceback then
        top.xml_doc:text(trace.traceback)
      end
      top.xml_doc:up()
    end

    return nil, true
  end

  if enable_split_output_xml == nil then
    busted.subscribe({ 'exit' }, handler.exit)
  end
  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'test', 'start' }, handler.testStart, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'error', 'it' }, handler.errorTest)
  busted.subscribe({ 'failure', 'it' }, handler.failureTest)
  busted.subscribe({ 'error' }, handler.error)
  busted.subscribe({ 'failure' }, handler.error)

  return handler
end
