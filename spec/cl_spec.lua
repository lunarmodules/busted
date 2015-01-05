local utils = require 'pl.utils'
local path = require('pl.path')
local ditch = ' > /dev/null 2>&1'
if path.is_windows then
  ditch = ' 1> NUL 2>NUL'
end
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
    success, exitcode = execute('bin/busted --pattern=_tags.lua$')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute('bin/busted --pattern=_tags.lua$ --tags=tag1')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute('bin/busted --pattern=_tags.lua$ --tags=tag1,tag2')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    error_end()
  end)

  it('tests running with --exclude-tags specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=_tags.lua$ --exclude-tags=tag1,tag2')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute('bin/busted --pattern=_tags.lua$ --exclude-tags=tag2')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    error_end()
  end)

  it('tests running with --tags and --exclude-tags specified', function ()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=_tags.lua$ --tags=tag1 --exclude-tags=tag1')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    success, exitcode = execute('bin/busted --pattern=_tags.lua$ --tags=tag3 --exclude-tags=tag4')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('tests running with --lang specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=cl_success.lua$ --lang=en')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute('bin/busted --pattern=cl_success --lang=not_found_here')
    assert.is_false(success)
    assert.is_equal(1, exitcode)  -- busted errors out on non-available language
    error_end()
  end)

  it('tests running with --version specified', function()
    local success, exitcode
    success, exitcode = execute('bin/busted --version')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
  end)

  it('tests running with --help specified', function()
    local success, exitcode
    success, exitcode = execute('bin/busted --help')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
  end)

  it('tests running a non-compiling testfile', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=cl_compile_fail.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running a testfile throwing errors when being run', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=cl_execute_fail.lua$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)

  it('tests running with --output specified', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=cl_success.lua$ --output=TAP')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    success, exitcode = execute('bin/busted --pattern=cl_two_failures.lua$ --output=not_found_here')
    assert.is_false(success)
    assert.is_equal(3, exitcode)  -- outputter missing, defaults to default outputter +1 error
    error_end()
  end)

  it('tests no tests to exit with a fail-exitcode', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=this_filename_does_simply_not_exist$')
    assert.is_false(success)
    assert.is_equal(1, exitcode)
    error_end()
  end)


end)

describe('Tests failing tests through the commandline', function()
  it('tests failing setup/before_each/after_each/teardown functions', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=cl_failing_support.lua$')
    assert.is_false(success)
    assert.is_equal(8, exitcode)
    error_end()
  end)

  it('tests failing support functions as errors', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_failing_support.lua$')
    local _, numErrors = result:gsub('Error → .-\n','')
    assert.is_equal(12, numErrors)
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
    success, exitcode = execute('bin/busted spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    success, exitcode = execute('bin/busted --tags=tag1 spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(2, exitcode)
    success, exitcode = execute('bin/busted --tags=tag1,tag2 spec/cl_standalone.lua')
    assert.is_false(success)
    assert.is_equal(3, exitcode)
    error_end()
  end)
end)

describe('Tests distinguish between errors and failures', function()
  it('by detecting errors as test errors', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_errors.lua$ --tags=testerr')
    local errmsg = result:match('(Error → .-)\n')
    assert.is_truthy(errmsg)
    error_end()
  end)

  it('by detecting assert failures as test failures', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_two_failures.lua$')
    local failmsg = result:match('(Failure → .-)\n')
    assert.is_truthy(failmsg)
    error_end()
  end)

  it('by detecting Lua runtime errors as test errors', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_errors.lua$ --tags=luaerr')
    local failmsg = result:match('(Error → .-)\n')
    assert.is_truthy(failmsg)
    error_end()
  end)
end)

describe('Tests stack trackback', function()
  it('when throwing an error', function()
    error_start()
    local result = run('bin/busted --verbose --pattern=cl_errors.lua$ --tags=testerr')
    local errmsg = result:match('(stack traceback:.*)\n')
    local expected = [[stack traceback:
	./spec/cl_errors.lua:6: in function <./spec/cl_errors.lua:5>
]]
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when assertion fails', function()
    error_start()
    local result = run('bin/busted --verbose --pattern=cl_two_failures.lua$ --tags=err1')
    local errmsg = result:match('(stack traceback:.*)\n')
    local expected = [[stack traceback:
	./spec/cl_two_failures.lua:6: in function <./spec/cl_two_failures.lua:5>
]]
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when Lua runtime error', function()
    error_start()
    local result = run('bin/busted --verbose --pattern=cl_errors.lua$ --tags=luaerr')
    local errmsg = result:match('(stack traceback:.*)\n')
    local expected = [[stack traceback:
	./spec/cl_errors.lua:11: in function <./spec/cl_errors.lua:9>
]]
    assert.is_equal(expected, errmsg)
    error_end()
  end)
end)

describe('Tests error messages through the command line', function()
  it('when throwing errors in a test', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_errors.lua$ --tags=testerr')
    local err = result:match('(Error → .-)\n')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expectedErr = "Error → ./spec/cl_errors.lua @ 5"
    local expectedMsg = "./spec/cl_errors.lua:6: force an error"
    assert.is_equal(expectedErr, err)
    assert.is_equal(expectedMsg, errmsg)
    error_end()
  end)

  it('when throwing an error table', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --tags=table --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expected = './spec/cl_error_messages.lua:5: {'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when throwing a nil error', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --tags=nil --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expected = './spec/cl_error_messages.lua:9: Nil error'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when throwing an error table with __tostring', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --tags=tostring --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expected = './spec/cl_error_messages.lua:17: {}'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when throwing after a pcall', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --tags=pcall --pattern=cl_error_messages.lua$')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expected = './spec/cl_error_messages.lua:22: error after pcall'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when running a non-compiling testfile', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_compile_fail.lua$')
    local errmsg = result:match('(Error → .-:%d+:) ')
    local expected = "Error → ./spec/cl_compile_fail.lua:3:"
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when a testfile throws errors', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_execute_fail.lua$')
    local err = result:match('(Error → .-)\n')
    local errmsg = result:match('\n(%./spec/cl_execute_fail%.lua:%d+:.-)\n')
    local expectedErr = 'Error → ./spec/cl_execute_fail.lua @ 4'
    local expectedMsg = './spec/cl_execute_fail.lua:4: This compiles fine, but throws an error when being run'
    assert.is_equal(expectedErr, err)
    assert.is_equal(expectedMsg, errmsg)
    error_end()
  end)

  it('when output library not found', function()
    error_start()
    local result = run('bin/busted --pattern=cl_two_failures.lua$ --output=not_found_here')
    local errmsg = result:match('(.-)\n')
    local expected = 'Cannot load output library: not_found_here'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when no test files matching Lua pattern', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=this_filename_does_simply_not_exist$')
    local errmsg = result:match('(.-)\n')
    local expected = 'No test files found matching Lua pattern: this_filename_does_simply_not_exist$'
    assert.is_equal(expected, errmsg)
    error_end()
  end)
end)

describe('Tests moonscript error messages through the command line', function()
  it('when assertion fails', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_moonscript_error_messages.moon$ --tags=fail')
    local err = result:match('(Failure → .-)\n')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expectedErr = "Failure → ./spec/cl_moonscript_error_messages.moon @ 4"
    local expectedMsg = "./spec/cl_moonscript_error_messages.moon:5: Expected objects to be equal."
    assert.is_equal(expectedErr, err)
    assert.is_equal(expectedMsg, errmsg)
    error_end()
  end)

  it('when throwing string errors', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_moonscript_error_messages.moon$ --tags=string')
    local err = result:match('(Error → .-)\n')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expectedErr = "Error → ./spec/cl_moonscript_error_messages.moon @ 16"
    local expectedMsg = "./spec/cl_moonscript_error_messages.moon:17: error message"
    assert.is_equal(expectedErr, err)
    assert.is_equal(expectedMsg, errmsg)
    error_end()
  end)

  it('when throwing an error table', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --tags=table --pattern=cl_moonscript_error_messages.moon$')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expected = './spec/cl_moonscript_error_messages.moon:9: {'
    assert.is_equal(expected, errmsg)
    error_end()
  end)

  it('when throwing a nil error', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --tags=nil --pattern=cl_moonscript_error_messages.moon$')
    local errmsg = result:match('\n(%./spec/.-)\n')
    local expected = './spec/cl_moonscript_error_messages.moon:13: Nil error'
    assert.is_equal(expected, errmsg)
    error_end()
  end)
end)

describe('Tests pending through the commandline', function()
  it('skips tests inside pending scope', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --pattern=cl_pending.lua$')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('detects tests as pending', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --pattern=cl_pending.lua$')
    local line1 = result:match('.-\n')
    local _, pendingDots = line1:gsub('%.', '')
    local _, numPending = result:gsub('Pending → .-\n', '')
    assert.is_equal(2, pendingDots)
    assert.is_equal(2, numPending)
    error_end()
  end)

  it('--suppress-pending option is honored', function()
    error_start()
    local result = run('bin/busted --output=plainTerminal --suppress-pending --pattern=cl_pending.lua$')
    local line1 = result:match('.-\n')
    local _, pendingDots = line1:gsub('%.', '')
    local _, numPending = result:gsub('Pending → .-\n', '')
    assert.is_equal(0, pendingDots)
    assert.is_equal(0, numPending)
    error_end()
  end)
end)

describe('Tests random seed through the commandline', function()
  it('test seed value', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --seed=12345 --pattern=cl_random_seed.lua$')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('test invalid seed value defaults to a valid seed value', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --seed=abcd --pattern=cl_random_seed.lua$')
    assert.is_false(success)
    assert.is_equal(2, exitcode) -- fails cl_random_seed test +1 error
    error_end()
  end)

  it('test failure outputs random seed value', function()
    error_start()
    local result = run('bin/busted --seed=789 --pattern=cl_random_seed.lua$')
    local seed = result:match('Random Seed: (%d+)\n')
    assert.is_equal(789, tonumber(seed))
    error_end()
  end)

  it('test non-randomized failure does not output seed value', function()
    error_start()
    local result = run('bin/busted --seed=789 --pattern=cl_two_failures.lua$')
    local seed = result:match('Random Seed:')
    assert.is_equal(nil, seed)
    error_end()
  end)
end)

describe('Tests randomize/shuffle commandline option', function()
  it('forces test shuffling for non-randomized tests', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --shuffle --pattern=cl_randomize.lua$')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)

  it('forces test randomization for non-randomized tests', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --randomize --pattern=cl_randomize.lua$')
    assert.is_true(success)
    assert.is_equal(0, exitcode)
    error_end()
  end)
end)

describe('Tests repeat commandline option', function()
  it('forces tests to repeat n times', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('bin/busted --repeat=2 --pattern=cl_two_failures.lua$')
    assert.is_false(success)
    assert.is_equal(4, exitcode)
    error_end()
  end)
end)
