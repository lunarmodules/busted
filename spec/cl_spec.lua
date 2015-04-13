local utils = require 'pl.utils'
local path = require 'pl.path'
local normpath = path.normpath
local busted_cmd = path.is_windows and 'lua bin/busted' or 'bin/busted'
local ditch = path.is_windows and ' 1> NUL 2>NUL' or ' > /dev/null 2>&1'

--ditch = ''  -- uncomment this line, to show output of failing commands, for debugging

local error_started
local error_start = function()
  if ditch ~= '' then return end
  print('================================================')
  print('==  Error block follows                       ==')
  print('================================================')
  error_started = true
end
local error_end = function()
  if ditch ~= '' then return end
  print('================================================')
  print('==  Error block ended, all according to plan  ==')
  print('================================================')
  error_started = false
end

-- if exitcode >256, then take MSB as exit code
local modexit = function(exitcode)
  if exitcode>255 then
    return math.floor(exitcode/256), exitcode - math.floor(exitcode/256)*256
  else
    return exitcode
  end
end

local execute = function(cmd)
  local success, exitcode = utils.execute(cmd..ditch)
  return not not success, modexit(exitcode)
end

local run = function(cmd)
  local p = io.popen(cmd, 'r')
  local out = p:read('*a')
  p:close()
  return out
end


describe('Tests the busted command-line options', function()

  setup(function()
  end)

  after_each(function()
    if error_started then
      print('================================================')
      print('==  Error block ended, something was wrong    ==')
      print('================================================')
      error_started = false
    end
  end)
  

  it('tests running with --tags specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$')
    assert.is_false(success)
    assert.is_equal(8, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=tag1')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=tag1,tag2')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=tag1 --tags=tag2')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
    error_end()
  end)

  it('tests running with --exclude-tags specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --exclude-tags=tag1,tag2,dtag1,dtag2')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --exclude-tags=tag2,dtag1,dtag2')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --exclude-tags=tag2 --exclude-tags=dtag1,dtag2')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    error_end()
  end)

  it('tests running with --tags and --exclude-tags specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=tag1 --exclude-tags=tag1')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=tag3 --exclude-tags=tag4')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running with --tags specified in describe', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=dtag1')
    assert.is_false(success)
    assert.is_equal(5, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_tags.lua$ --tags=dtag2')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running with --filter specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$')
    assert.is_false(success)
    assert.is_equal(8, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter="pattern1"')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter="pattern2"')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter="pattern1" --filter="pattern2"')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
    error_end()
  end)

  it('tests running with --filter-out specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter-out="pattern1"')
    assert.is_false(success)
    assert.is_equal(6, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter-out="pattern%d"')
    assert.is_false(success)
    assert.is_equal(5, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter-out="patt1" --filter-out="patt2"')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter-out="patt.*(%d)"')
    assert.is_true(success)
    error_end()
  end)

  it('tests running with --filter and --filter-out specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter="pattern3" --filter-out="patt.*[12]"')
    assert.is_true(success)
    error_end()
  end)

  it('tests running with --filter specified in describe', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter="patt1"')
    assert.is_false(success)
    assert.is_equal(5, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=_filter.lua$ --filter="patt2"')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running with --lazy specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --lazy --pattern=_tags.lua$')
    assert.is_false(success)
    assert.is_equal(7, exitcode)
    success, exitcode = execute(busted_cmd .. ' --lazy --pattern=_tags.lua$ --tags=tag1')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute(busted_cmd .. ' --lazy --pattern=_tags.lua$ --tags=tag1,tag2')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute(busted_cmd .. ' --lazy --pattern=_tags.lua$ --tags=tag1 --tags=tag2')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    error_end()
  end)

  it('tests running with -l specified', function()
    local result = run(busted_cmd .. ' -l --pattern=cl_list.lua$')
    local expected = 'spec/cl_list.lua:4: Tests list test 1\n' ..
                     'spec/cl_list.lua:7: Tests list test 2\n' ..
                     'spec/cl_list.lua:10: Tests list test 3\n'
    assert.is_equal(normpath(expected), result)
  end)

  it('tests running with --list specified', function()
    local result = run(busted_cmd .. ' --list --pattern=cl_list.lua$')
    local expected = 'spec/cl_list.lua:4: Tests list test 1\n' ..
                     'spec/cl_list.lua:7: Tests list test 2\n' ..
                     'spec/cl_list.lua:10: Tests list test 3\n'
    assert.is_equal(normpath(expected), result)
  end)

  it('tests running with --lpath specified', function()
    local success, exitcode
    success, exitcode = execute(busted_cmd .. ' --lpath="spec/?.lua" spec/cl_lua_path.lua')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
  end)

  it('tests running with --lang specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_success.lua$ --lang=en')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_success --lang=not_found_here')
    assert.is_false(success)
    assert.is_equal(1, exitcode)  -- busted errors out on non-available language
    error_end()
  end)

  it('tests running with --version specified', function()
    local success, exitcode
    success, exitcode = execute(busted_cmd .. ' --version')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
  end)

  it('tests running with --help specified', function()
    local success, exitcode
    success, exitcode = execute(busted_cmd .. ' --help')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
  end)

  it('tests running a non-compiling testfile', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_compile_fail.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running a testfile throwing errors when being run', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_execute_fail.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running with --output specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_success.lua$ --output=TAP')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_two_failures.lua$ --output=not_found_here')
    assert.is_false(success)
    assert.is_equal(3, exitcode)  -- outputter missing, defaults to default outputter +1 error
    error_end()
  end)

  it('tests running with --output specified with module in lua path', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_success.lua$ --output=busted.outputHandlers.TAP')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('tests no tests to exit with a fail-exitcode', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=this_filename_does_simply_not_exist$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

end)

describe('Tests failing tests through the commandline', function()
  it('tests failing setup/before_each/after_each/teardown functions', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_failing_support.lua$')
    assert.is_false(success)
    assert.is_equal(16, exitcode)
    error_end()
  end)

  it('tests failing support functions as errors', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_failing_support.lua$')
    local _, numErrors = result:gsub('Error %-> .-\n','')
    assert.is_equal(16, numErrors)
    error_end()
  end)
end)

describe('Test busted running standalone', function()
  it('tests running with --tags specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('lua spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute('lua spec/cl_standalone.lua --tags=tag1')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute('lua spec/cl_standalone.lua --tags=tag1,tag2')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    error_end()
  end)

  it('tests running with --exclude-tags specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('lua spec/cl_standalone.lua --exclude-tags=tag1,tag2')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute('lua spec/cl_standalone.lua --exclude-tags=tag2')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    error_end()
  end)

  it('tests running with --tags and --exclude-tags specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute('lua spec/cl_standalone.lua --tags=tag1 --exclude-tags=tag1')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    success, exitcode = execute('lua spec/cl_standalone.lua --tags=tag3 --exclude-tags=tag4')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('tests running with --helper specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute('lua spec/cl_standalone.lua --helper=spec/cl_helper_script.lua -Xhelper "--fail-teardown,--fail-after-each"')
    assert.is_false(success)
    assert.is_equal(9, exitcode)
    error_end()
  end)

  it('tests running with --version specified', function()
    local success, exitcode
    success, exitcode = execute('lua spec/cl_standalone.lua --version')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
  end)

  it('tests running with --help specified', function()
    local success, exitcode
    success, exitcode = execute('lua spec/cl_standalone.lua --help')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
  end)
end)

describe('Test busted command-line runner', function()
  it('runs standalone spec', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute(busted_cmd .. ' --tags=tag1 spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute(busted_cmd .. ' --tags=tag1,tag2 spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    error_end()
  end)
end)

describe('Tests distinguish between errors and failures', function()
  it('by detecting errors as test errors', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_errors.lua$ --tags=testerr')
    local errmsg = result:match('(Error %-> .-)\n')
    assert.is_truthy(errmsg)
    error_end()
  end)

  it('by detecting assert failures as test failures', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_two_failures.lua$')
    local failmsg = result:match('(Failure %-> .-)\n')
    assert.is_truthy(failmsg)
    error_end()
  end)

  it('by detecting Lua runtime errors as test errors', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_errors.lua$ --tags=luaerr')
    local failmsg = result:match('(Error %-> .-)\n')
    assert.is_truthy(failmsg)
    error_end()
  end)
end)

describe('Tests stack trackback', function()
  it('when throwing an error', function()
    error_start()
    local result = run(busted_cmd .. ' --verbose --pattern=cl_errors.lua$ --tags=testerr')
    local errmsg = result:match('(stack traceback:.*)\n')
    local expected = [[stack traceback:
	spec/cl_errors.lua:6: in function <spec/cl_errors.lua:5>
]]
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when assertion fails', function()
    error_start()
    local result = run(busted_cmd .. ' --verbose --pattern=cl_two_failures.lua$ --tags=err1')
    local errmsg = result:match('(stack traceback:.*)\n')
    local expected = [[stack traceback:
	spec/cl_two_failures.lua:6: in function <spec/cl_two_failures.lua:5>
]]
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when Lua runtime error', function()
    error_start()
    local result = run(busted_cmd .. ' --verbose --pattern=cl_errors.lua$ --tags=luaerr')
    local errmsg = result:match('(stack traceback:.*)\n')
    local expected = [[stack traceback:
	spec/cl_errors.lua:11: in function <spec/cl_errors.lua:9>
]]
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)
end)

describe('Tests error messages through the command line', function()
  it('when throwing errors in a test', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_errors.lua$ --tags=testerr')
    local err = result:match('(Error %-> .-)\n')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expectedErr = "Error -> spec/cl_errors.lua @ 5"
    local expectedMsg = "spec/cl_errors.lua:6: force an error"
    assert.is_equal(normpath(expectedErr), err)
    assert.is_equal(normpath(expectedMsg), errmsg)
    error_end()
  end)

  it('when throwing an error table', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --tags=table --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expected = 'spec/cl_error_messages.lua:5: {'
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when throwing a nil error', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --tags=nil --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expected = 'spec/cl_error_messages.lua:9: Nil error'
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when throwing an error table with __tostring', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --tags=tostring --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expected = 'spec/cl_error_messages.lua:17: {}'
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when throwing after a pcall', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --tags=pcall --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expected = 'spec/cl_error_messages.lua:22: error after pcall'
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when running a non-compiling testfile', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_compile_fail.lua$')
    local errmsg = result:match('(Error %-> .-:%d+:) ')
    local expected = "Error -> spec/cl_compile_fail.lua:3:"
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when a testfile throws errors', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_execute_fail.lua$')
    local err = result:match('(Error %-> .-)\n')
    local errmsg = result:match('\n(spec[/\\]cl_execute_fail%.lua:%d+:.-)\n')
    local expectedErr = 'Error -> spec/cl_execute_fail.lua @ 4'
    local expectedMsg = 'spec/cl_execute_fail.lua:4: This compiles fine, but throws an error when being run'
    assert.is_equal(normpath(expectedErr), err)
    assert.is_equal(normpath(expectedMsg), errmsg)
    error_end()
  end)

  it('when output library not found', function()
    error_start()
    local result = run(busted_cmd .. ' --pattern=cl_two_failures.lua$ --output=not_found_here 2>&1')
    local errmsg = result:match('(.-)\n')
    local expected = 'busted: error: Cannot load output library: not_found_here'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when helper script not found', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_two_failures.lua$ --helper=not_found_here 2>&1')
    local err = result:match('Error %-> .-:%d+: (.-)\n')
    local errmsg = result:match('(.-)\n')
    local expectedErr = "module 'not_found_here' not found:"
    local expectedMsg = 'busted: error: Cannot load helper script: not_found_here'
    assert.is_equal(expectedErr, err)
    assert.is_equal(expectedMsg, errmsg)
    error_end()
  end)

  it('when helper lua script not found', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_two_failures.lua$ --helper=not_found_here.lua 2>&1')
    local err = result:match('Error %-> (.-)\n')
    local errmsg = result:match('(.-)\n')
    local expectedErr = 'cannot open not_found_here.lua: No such file or directory'
    local expectedMsg = 'busted: error: Cannot load helper script: not_found_here.lua'
    assert.is_equal(normpath(expectedErr), err)
    assert.is_equal(expectedMsg, errmsg)
    error_end()
  end)

  it('when no test files matching Lua pattern', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=this_filename_does_simply_not_exist$')
    local errmsg = result:match('Error %-> (.-)\n')
    local expected = 'No test files found matching Lua pattern: this_filename_does_simply_not_exist$'
    assert.is_equal(expected, errmsg)
    error_end()
  end)
end)

local has_moon = pcall(require, 'moonscript')
local describe_moon = (has_moon and describe or pending)

describe_moon('Tests moonscript error messages through the command line', function()
  it('when assertion fails', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_moonscript_error_messages.moon$ --tags=fail')
    local err = result:match('(Failure %-> .-)\n')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expectedErr = "Failure -> spec/cl_moonscript_error_messages.moon @ 4"
    local expectedMsg = "spec/cl_moonscript_error_messages.moon:5: Expected objects to be equal."
    assert.is_equal(normpath(expectedErr), err)
    assert.is_equal(normpath(expectedMsg), errmsg)
    error_end()
  end)

  it('when throwing string errors', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_moonscript_error_messages.moon$ --tags=string')
    local err = result:match('(Error %-> .-)\n')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expectedErr = "Error -> spec/cl_moonscript_error_messages.moon @ 16"
    local expectedMsg = "spec/cl_moonscript_error_messages.moon:17: error message"
    assert.is_equal(normpath(expectedErr), err)
    assert.is_equal(normpath(expectedMsg), errmsg)
    error_end()
  end)

  it('when throwing an error table', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --tags=table --pattern=cl_moonscript_error_messages.moon$')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expected = 'spec/cl_moonscript_error_messages.moon:9: {'
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)

  it('when throwing a nil error', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --tags=nil --pattern=cl_moonscript_error_messages.moon$')
    local errmsg = result:match('\n(spec[/\\].-)\n')
    local expected = 'spec/cl_moonscript_error_messages.moon:13: Nil error'
    assert.is_equal(normpath(expected), errmsg)
    error_end()
  end)
end)

describe('Tests pending through the commandline', function()
  it('skips tests inside pending scope', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --pattern=cl_pending.lua$')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('detects tests as pending', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --pattern=cl_pending.lua$')
    local line1 = result:match('.-\n')
    local _, pendingDots = line1:gsub('%.', '')
    local _, numPending = result:gsub('Pending %-> .-\n', '')
    assert.is_equal(2, pendingDots)
    assert.is_equal(2, numPending)
    error_end()
  end)

  it('--suppress-pending option is honored', function()
    error_start()
    local result = run(busted_cmd .. ' --output=plainTerminal --suppress-pending --pattern=cl_pending.lua$')
    local line1 = result:match('.-\n')
    local _, pendingDots = line1:gsub('%.', '')
    local _, numPending = result:gsub('Pending %-> .-\n', '')
    assert.is_equal(0, pendingDots)
    assert.is_equal(0, numPending)
    error_end()
  end)
end)

describe('Tests random seed through the commandline', function()
  it('test seed value', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --seed=12345 --pattern=cl_random_seed.lua$')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('test invalid seed value exits with error', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --seed=abcd --pattern=cl_random_seed.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('test failure outputs random seed value', function()
    error_start()
    local result = run(busted_cmd .. ' --seed=789 --pattern=cl_random_seed.lua$')
    local seed = result:match('Random seed: (%d+)\n')
    assert.is_equal(789, tonumber(seed))
    error_end()
  end)

  it('test non-randomized failure does not output seed value', function()
    error_start()
    local result = run(busted_cmd .. ' --seed=789 --pattern=cl_two_failures.lua$')
    local seed = result:match('Random seed:')
    assert.is_equal(nil, seed)
    error_end()
  end)
end)

describe('Tests shuffle commandline option', function()
  for _, opt in ipairs({ '--shuffle', '--shuffle-tests' }) do
    it('forces test shuffling for non-randomized tests, ' .. opt, function()
      local success, exitcode
      error_start()
      success, exitcode = execute(busted_cmd .. ' ' .. opt .. ' --pattern=cl_randomize.lua$')
      assert.is_true(success)
      assert.is_equal(0, exitcode)
      error_end()
    end)
  end
end)

describe('Tests sort commandline option', function()
  for _, opt in ipairs({ '--sort', '--sort-tests' }) do
    it('sorts tests by name, ' .. opt, function()
      local success, exitcode
      error_start()
      success, exitcode = execute(busted_cmd .. ' ' .. opt .. ' --pattern=cl_sort.lua$')
      assert.is_true(success)
      assert.is_equal(0, exitcode)
      error_end()
    end)
  end
end)

describe('Tests repeat commandline option', function()
  it('forces tests to repeat n times', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --repeat=2 --pattern=cl_two_failures.lua$')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
    error_end()
  end)

  it('exits with error when repeat is invalid', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --repeat=abc --pattern=cl_success.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)
end)

describe('Tests no-keep-going commandline option', function()
  it('skips all tests after first error', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --no-keep-going --pattern=cl_two_failures.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)
end)

describe('Tests no-recursive commandline option', function()
  it('does not run any tests in subdirectories', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --no-recursive --pattern=cl_two_failures.lua$ .')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)
end)

describe('Tests no-auto-insulate commandline option', function()
  it('does not insulate test files', function()
    local success, exitcode
    error_start()
    success, exitcode = execute(busted_cmd .. ' --no-auto-insulate --pattern=insulate_file.*.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)
end)

describe('Tests Xoutput commandline option', function()
  it('forwards no options to output handler when no options specified', function()
    local result = run(busted_cmd .. ' --output=spec/cl_output_handler.lua --pattern=cl_success.lua$')
    local status = result:match('^%[(.-)]')
    assert.is_equal(' success', status)
  end)

  it('forwards single option to output handler', function()
    local result = run(busted_cmd .. ' --output=spec/cl_output_handler.lua -Xoutput "--time" --pattern=cl_success.lua$')
    local timestamp = result:match('^%[(.-)]')
    assert.is_equal('Fri Jan  2 10:17:36 1970', timestamp)
  end)

  it('forwards multiple options to output handler', function()
    local result = run(busted_cmd .. ' --output=spec/cl_output_handler.lua -Xoutput "--time,--time-format=!%H:%M:%S" --pattern=cl_success.lua$')
    local timestamp = result:match('^%[(.-)]')
    assert.is_equal('10:17:36', timestamp)
  end)

  it('forwards multiple options to output handler using multiple -Xoutput', function()
    local result = run(busted_cmd .. ' --output=spec/cl_output_handler.lua -Xoutput "--time" -Xoutput "--time-format=!%H:%M:%S" --pattern=cl_success.lua$')
    local timestamp = result:match('^%[(.-)]')
    assert.is_equal('10:17:36', timestamp)
  end)
end)

describe('Tests Xhelper commandline option', function()
  it('forwards no options to helper script when no options specified', function()
    local success = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua --pattern=cl_success.lua$')
    assert.is_true(success)
  end)

  it('forwards single option to helper script', function()
    local success, exitcode = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua -Xhelper "--fail-before-each" --pattern=cl_success.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
  end)

  it('forwards multiple options to helper script', function()
    local success, exitcode = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua -Xhelper "--fail-before-each,--fail-after-each" --pattern=cl_success.lua$')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
  end)

  it('forwards multiple options to helper script using multiple -Xhelper', function()
    local success, exitcode = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua -Xhelper "--fail-before-each" -Xhelper "--fail-after-each" --pattern=cl_success.lua$')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
  end)
end)

describe('Tests helper script', function()
  it('can add setup to test suite', function()
    local success, exitcode = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua -Xhelper "--fail-setup" --pattern=cl_two_failures.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
  end)

  it('can add teardown to test suite', function()
    local success, exitcode = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua -Xhelper "--fail-teardown" --pattern=cl_two_failures.lua$')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
  end)

  it('runs setup/teardown for mutiple runs', function()
    local success, exitcode = execute(busted_cmd .. ' --helper=spec/cl_helper_script.lua -Xhelper "--fail-setup,--fail-teardown" --pattern=cl_success.lua$ --repeat=2')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
  end)

  it('runs setup/teardown for mutiple runs with --lazy', function()
    local success, exitcode = execute(busted_cmd .. ' --lazy --helper=spec/cl_helper_script.lua -Xhelper "--fail-setup,--fail-teardown" --pattern=cl_success.lua$ --repeat=2')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
  end)
end)
