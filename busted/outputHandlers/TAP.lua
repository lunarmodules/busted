local pretty = require 'pl.pretty'
local io = io
local type = type
local string_format = string.format
local string_gsub = string.gsub
local io_write = io.write
local io_flush = io.flush

local function print(msg)
  io_write(msg .. '\n')
end

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()

  local success = 'ok %u - %s'
  local failure = 'not ' .. success
  local skip = 'ok %u - # SKIP %s'
  local counter = 0

  handler.suiteReset = function()
    counter = 0
    return nil, true
  end

  handler.suiteEnd = function()
    print('1..' .. counter)
    io_flush()
    return nil, true
  end

  local function showFailure(t)
    local message = t.message
    local trace = t.trace or {}

    if message == nil then
      message = 'Nil error'
    elseif type(message) ~= 'string' then
      message = pretty.write(message)
    end

    print(string_format(failure, counter, t.name))
    if t.element.trace.short_src then
      print('# ' .. t.element.trace.short_src .. ' @ ' .. t.element.trace.currentline)
    end
    if t.randomseed then
      print('# Random seed: ' .. t.randomseed)
    end
    print('# Failure message: ' .. string_gsub(message, '\n', '\n# '))
    if options.verbose and trace.traceback then
      print('# ' .. string_gsub(string_gsub(trace.traceback, '^\n', '', 1), '\n', '\n# '))
    end
  end

  handler.testStart = function(element, parent)
    local trace = element.trace
    if options.verbose and trace and trace.short_src then
      local fileline = trace.short_src .. ' @ ' ..  trace.currentline .. ': '
      local testName = fileline .. handler.getFullName(element)
      print('# ' .. testName)
    end
    io.flush()

    return nil, true
  end

  handler.testEnd = function(element, parent, status, trace)
    counter = counter + 1
    if status == 'success' then
      local t = handler.successes[#handler.successes]
      print(string_format(success, counter, t.name))
    elseif status == 'pending' then
      local t = handler.pendings[#handler.pendings]
      print(string_format(skip, counter, (t.message or t.name)))
    elseif status == 'failure' then
      showFailure(handler.failures[#handler.failures])
    elseif status == 'error' then
      showFailure(handler.errors[#handler.errors])
    end
    io.flush()

    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    if element.descriptor ~= 'it' then
      counter = counter + 1
      showFailure(handler.errors[#handler.errors])
    end
    io.flush()

    return nil, true
  end

  busted.subscribe({ 'suite', 'reset' }, handler.suiteReset)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'test', 'start' }, handler.testStart, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'error' }, handler.error)

  return handler
end
