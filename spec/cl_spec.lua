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


it('Tests the busted command-line options', function()

  setup(function()
    require('pl')
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
    assert.is_true(success)
    assert.is_equal(0, exitcode)
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

--[[  --TODO: uncomment this failing test and fix it
describe('Tests failing tests through the commandline', function()
  local old_ditch
  before_each(function()
    old_ditch, ditch = ditch, ''   -- dump this test output only
  end)
  after_each(function()
    ditch = old_ditch
  end)
  
  it('tests failing setup/before_each/after_each/teardown functions', function()
    local success, exitcode
    error_start()
    success, exitcode = execute('busted --pattern=cl_failing_support.lua$')
    assert.is_false(success)
    assert.is_equal(8, exitcode)
    error_end()
  end)
end)
--]]
