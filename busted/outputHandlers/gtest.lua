local pretty = require 'pl.pretty'
local term = require 'term'
local luassert = require 'luassert'
local io = io
local type = type
local ipairs = ipairs
local string_format = string.format
local io_write = io.write
local io_flush = io.flush
local colors

local isatty = io.type(io.stdout) == 'file' and term.isatty(io.stdout)

return function(options)
  local busted = require 'busted'
  local handler = require 'busted.outputHandlers.base'()

  local cli = require 'cliargs'
  local args = options.arguments

  cli:set_name('gtest output handler')
  cli:flag('--color', 'force use of color')
  cli:flag('--plain', 'force use of no color')

  local cliArgs, err = cli:parse(args)
  if not cliArgs and err then
    io.stderr:write(string.format('%s: %s\n\n', cli.name, err))
    io.stderr:write(cli.printer.generate_help_and_usage().. '\n')
    os.exit(1)
  end

  if cliArgs.plain then
    colors = setmetatable({}, {__index = function() return function(s) return s end end})
    luassert:set_parameter("TableErrorHighlightColor", "none")

  elseif cliArgs.color then
    colors = require 'term.colors'
    luassert:set_parameter("TableErrorHighlightColor", "red")

  else
    if package.config:sub(1,1) == '\\' and not os.getenv("ANSICON") or not isatty then
      -- Disable colors on Windows.
      colors = setmetatable({}, {__index = function() return function(s) return s end end})
      luassert:set_parameter("TableErrorHighlightColor", "none")
    else
      colors = require 'term.colors'
      luassert:set_parameter("TableErrorHighlightColor", "red")
    end
  end

  local repeatSuiteString = '\nRepeating all tests (run %u of %u) . . .\n\n'
  local randomizeString  = colors.yellow('Note: Randomizing test order with a seed of %u.\n')
  local suiteStartString = colors.green  ('[==========]') .. ' Running tests from scanned files.\n'
  local globalSetup      = colors.green  ('[----------]') .. ' Global test environment setup.\n'
  local fileStartString  = colors.green  ('[----------]') .. ' Running tests from %s\n'
  local runString        = colors.green  ('[ RUN      ]') .. ' %s\n'
  local successString    = colors.green  ('[       OK ]') .. ' %s (%.2f ms)\n'
  local skippedString    = colors.yellow ('[ SKIPPED  ]') .. ' %s (%.2f ms)\n'
  local failureString    = colors.red    ('[  FAILED  ]') .. ' %s (%.2f ms)\n'
  local errorString      = colors.magenta('[  ERROR   ]') .. ' %s (%.2f ms)\n'
  local fileEndString    = colors.green  ('[----------]') .. ' %u %s from %s (%.2f ms total)\n\n'
  local globalTeardown   = colors.green  ('[----------]') .. ' Global test environment teardown.\n'
  local suiteEndString   = colors.green  ('[==========]') .. ' %u %s from %u test %s ran. (%.2f ms total)\n'
  local successStatus    = colors.green  ('[  PASSED  ]') .. ' %u %s.\n'

  local summaryStrings = {
    skipped = {
      header = colors.yellow ('[ SKIPPED  ]') .. ' %u %s, listed below:\n',
      test   = colors.yellow ('[ SKIPPED  ]') .. ' %s\n',
      footer = ' %u SKIPPED %s\n',
    },

    failure = {
      header = colors.red    ('[  FAILED  ]') .. ' %u %s, listed below:\n',
      test   = colors.red    ('[  FAILED  ]') .. ' %s\n',
      footer = ' %u FAILED %s\n',
    },

    error = {
      header = colors.magenta('[  ERROR   ]') .. ' %u %s, listed below:\n',
      test   = colors.magenta('[  ERROR   ]') .. ' %s\n',
      footer = ' %u %s\n',
    },
  }

  local fileCount = 0
  local fileTestCount = 0
  local testCount = 0
  local successCount = 0
  local skippedCount = 0
  local failureCount = 0
  local errorCount = 0

  local pendingDescription = function(pending)
    local string = ''

    if type(pending.message) == 'string' then
      string = string .. pending.message .. '\n'
    elseif pending.message ~= nil then
      string = string .. pretty.write(pending.message) .. '\n'
    end

    return string
  end

  local failureDescription = function(failure)
    local string = failure.randomseed and ('Random seed: ' .. failure.randomseed .. '\n') or ''
    if type(failure.message) == 'string' then
      string = string .. failure.message
    elseif failure.message == nil then
      string = string .. 'Nil error'
    else
      string = string .. pretty.write(failure.message)
    end

    string = string .. '\n'

    if options.verbose and failure.trace and failure.trace.traceback then
      string = string .. failure.trace.traceback .. '\n'
    end

    return string
  end

  local getFileLine = function(element)
    local fileline = ''
    if element.trace or element.trace.short_src then
      fileline = colors.cyan(element.trace.short_src) .. ':' ..
                 colors.cyan(element.trace.currentline) .. ': '
    end
    return fileline
  end

  local getTestList = function(status, count, list, getDescription)
    local string = ''
    local header = summaryStrings[status].header
    if count > 0 and header then
      local tests = (count == 1 and 'test' or 'tests')
      local errors = (count == 1 and 'error' or 'errors')
      string = string_format(header, count, status == 'error' and errors or tests)

      local testString = summaryStrings[status].test
      if testString then
        for _, t in ipairs(list) do
          local fullname = getFileLine(t.element) .. colors.bright(t.name)
          string = string .. string_format(testString, fullname)
          if options.deferPrint then
            string = string .. getDescription(t)
          end
        end
      end
    end
    return string
  end

  local getSummary = function(status, count)
    local string = ''
    local footer = summaryStrings[status].footer
    if count > 0 and footer then
      local tests = (count == 1 and 'TEST' or 'TESTS')
      local errors = (count == 1 and 'ERROR' or 'ERRORS')
      string = string_format(footer, count, status == 'error' and errors or tests)
    end
    return string
  end

  local getSummaryString = function()
    local tests = (successCount == 1 and 'test' or 'tests')
    local string = string_format(successStatus, successCount, tests)

    string = string .. getTestList('skipped', skippedCount, handler.pendings, pendingDescription)
    string = string .. getTestList('failure', failureCount, handler.failures, failureDescription)
    string = string .. getTestList('error', errorCount, handler.errors, failureDescription)

    string = string .. ((skippedCount + failureCount + errorCount) > 0 and '\n' or '')
    string = string .. getSummary('skipped', skippedCount)
    string = string .. getSummary('failure', failureCount)
    string = string .. getSummary('error', errorCount)

    return string
  end

  local getFullName = function(element)
    return getFileLine(element) .. colors.bright(handler.getFullName(element))
  end

  handler.suiteReset = function()
    fileCount = 0
    fileTestCount = 0
    testCount = 0
    successCount = 0
    skippedCount = 0
    failureCount = 0
    errorCount = 0

    return nil, true
  end

  handler.suiteStart = function(suite, count, total, randomseed)
    if total > 1 then
      io_write(string_format(repeatSuiteString, count, total))
    end
    if randomseed then
      io_write(string_format(randomizeString, randomseed))
    end
    io_write(suiteStartString)
    io_write(globalSetup)
    io_flush()

    return nil, true
  end

  handler.suiteEnd = function(suite, count, total)
    local elapsedTime_ms = suite.duration * 1000
    local tests = (testCount == 1 and 'test' or 'tests')
    local files = (fileCount == 1 and 'file' or 'files')
    io_write(globalTeardown)
    io_write(string_format(suiteEndString, testCount, tests, fileCount, files, elapsedTime_ms))
    io_write(getSummaryString())
    io_flush()

    return nil, true
  end

  handler.fileStart = function(file)
    fileTestCount = 0
    io_write(string_format(fileStartString, file.name))
    io_flush()
    return nil, true
  end

  handler.fileEnd = function(file)
    local elapsedTime_ms = file.duration * 1000
    local tests = (fileTestCount == 1 and 'test' or 'tests')
    fileCount = fileCount + 1
    io_write(string_format(fileEndString, fileTestCount, tests, file.name, elapsedTime_ms))
    io_flush()
    return nil, true
  end

  handler.testStart = function(element, parent)
    io_write(string_format(runString, getFullName(element)))
    io_flush()

    return nil, true
  end

  handler.testEnd = function(element, parent, status, debug)
    local elapsedTime_ms = element.duration * 1000
    local string

    fileTestCount = fileTestCount + 1
    testCount = testCount + 1
    if status == 'success' then
      successCount = successCount + 1
      string = successString
    elseif status == 'pending' then
      skippedCount = skippedCount + 1
      string = skippedString
    elseif status == 'failure' then
      failureCount = failureCount + 1
      string = failureString
    elseif status == 'error' then
      errorCount = errorCount + 1
      string = errorString
    end

    io_write(string_format(string, getFullName(element), elapsedTime_ms))
    io_flush()

    return nil, true
  end

  handler.testFailure = function(element, parent, message, debug)
    if not options.deferPrint then
      io_write(failureDescription(handler.failures[#handler.failures]))
      io_flush()
    end
    return nil, true
  end

  handler.testError = function(element, parent, message, debug)
    if not options.deferPrint then
      io_write(failureDescription(handler.errors[#handler.errors]))
      io_flush()
    end
    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    if element.descriptor ~= 'it' then
      if not options.deferPrint then
        io_write(failureDescription(handler.errors[#handler.errors]))
        io_flush()
      end
      errorCount = errorCount + 1
    end

    return nil, true
  end

  busted.subscribe({ 'suite', 'reset' }, handler.suiteReset)
  busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
  busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
  busted.subscribe({ 'file', 'start' }, handler.fileStart)
  busted.subscribe({ 'file', 'end' }, handler.fileEnd)
  busted.subscribe({ 'test', 'start' }, handler.testStart, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'test', 'end' }, handler.testEnd, { predicate = handler.cancelOnPending })
  busted.subscribe({ 'failure', 'it' }, handler.testFailure)
  busted.subscribe({ 'error', 'it' }, handler.testError)
  busted.subscribe({ 'failure' }, handler.error)
  busted.subscribe({ 'error' }, handler.error)

  return handler
end
