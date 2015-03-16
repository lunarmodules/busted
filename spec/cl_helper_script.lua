-- supporting testfile; belongs to 'cl_spec.lua'

local setup = require 'busted'.setup
local teardown = require 'busted'.teardown
local before_each = require 'busted'.before_each
local after_each = require 'busted'.after_each
local assert = require 'busted'.assert
local cli = require 'cliargs'

cli:set_name('cl_helper_script')
cli:add_flag('--fail-setup', 'force setup to fail')
cli:add_flag('--fail-teardown', 'force teardown to fail')
cli:add_flag('--fail-before-each', 'force before each to fail')
cli:add_flag('--fail-after-each', 'force after each to fail')

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
