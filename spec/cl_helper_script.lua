-- supporting testfile; belongs to 'cl_spec.lua'

local setup = require 'busted'.setup
local teardown = require 'busted'.teardown
local before_each = require 'busted'.before_each
local after_each = require 'busted'.after_each
local subscribe = require 'busted'.subscribe
local assert = require 'busted'.assert
local cli = require 'cliargs'

cli:set_name('cl_helper_script')
cli:flag('--fail-setup', 'force setup to fail')
cli:flag('--fail-teardown', 'force teardown to fail')
cli:flag('--fail-before-each', 'force before each to fail')
cli:flag('--fail-after-each', 'force after each to fail')
cli:flag('--fail-suite-reset', 'force suite reset handler to fail')
cli:flag('--fail-suite-start', 'force suite start handler to fail')
cli:flag('--fail-suite-end', 'force suite end handler to fail')
cli:flag('--fail-file-start', 'force file start handler to fail')
cli:flag('--fail-file-end', 'force file end handler to fail')
cli:flag('--fail-describe-start', 'force describe start handler to fail')
cli:flag('--fail-describe-end', 'force describe end handler to fail')
cli:flag('--fail-test-start', 'force test start handler to fail')
cli:flag('--fail-test-end', 'force test end handler to fail')

local cliArgs = cli:parse(arg)

setup(function()
  assert(not cliArgs['fail-setup'])
end)

teardown(function()
  assert(not cliArgs['fail-teardown'])
end)

before_each(function()
  assert(not cliArgs['fail-before-each'])
end)

after_each(function()
  assert(not cliArgs['fail-after-each'])
end)

subscribe({'suite', 'reset'}, function()
  assert(not cliArgs['fail-suite-reset'])
  return nil, true
end)

subscribe({'suite', 'start'}, function()
  assert(not cliArgs['fail-suite-start'])
  return nil, true
end)

subscribe({'suite', 'end'}, function()
  assert(not cliArgs['fail-suite-end'])
  return nil, true
end)

subscribe({'file', 'start'}, function()
  assert(not cliArgs['fail-file-start'])
  return nil, true
end)

subscribe({'file', 'end'}, function()
  assert(not cliArgs['fail-file-end'])
  return nil, true
end)

subscribe({'describe', 'start'}, function()
  assert(not cliArgs['fail-describe-start'])
  return nil, true
end)

subscribe({'describe', 'end'}, function()
  assert(not cliArgs['fail-describe-end'])
  return nil, true
end)

subscribe({'test', 'start'}, function()
  assert(not cliArgs['fail-test-start'])
  return nil, true
end)

subscribe({'test', 'end'}, function()
  assert(not cliArgs['fail-test-end'])
  return nil, true
end)
