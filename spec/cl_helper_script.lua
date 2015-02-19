-- supporting testfile; belongs to 'cl_spec.lua'

local before_each = require 'busted'.before_each
local after_each = require 'busted'.after_each
local assert = require 'busted'.assert
local cli = require 'cliargs'

cli:set_name('cl_helper_script')
cli:add_flag('--fail-before-each', 'force before each to fail')
cli:add_flag('--fail-after-each', 'force after each to fail')

local cliArgs = cli:parse(arg)

before_each(function()
  assert(not cliArgs['fail-before-each'])
end)

after_each(function()
  assert(not cliArgs['fail-after-each'])
end)
