-- Runs internally an ev async test and checks the returned statuses.

local ev = require 'ev'
local generic_async = require 'generic_async_test'

local statuses = busted.run_internal_test(function()
  local loop = ev.Loop.default

  local eps = 0.000000000001
  local yield = function(done)
    ev.Timer.new(
      function()
        done()
      end,eps):start(loop)
  end

  setloop('ev')

  generic_async.setup_tests(yield,'ev')
end)

generic_async.describe_statuses(statuses)

local statuses = busted.run_internal_test(function()
  setloop('ev')
  it('this should timeout',async,function(done)
    settimeout(0.01)
    ev.Timer.new(done,0.1):start(ev.Loop.default)
    end)

  it('this should not timeout',async,function(done)
    settimeout(0.1)
    ev.Timer.new(done,0.01):start(ev.Loop.default)
  end)
end)

it('first test is timeout',function()
  local status = statuses[1]
  assert.is_equal(status.type,'failure')
  assert.is_equal(status.err,'test timeout elapsed (0.01s)')
  assert.is_equal(status.trace,'')
end)

it('second test is not timeout',function()
  local status = statuses[2]
  assert.is_equal(status.type,'success')
end)

