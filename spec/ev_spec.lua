-- Runs internally an ev async test and checks the returned statuses.

local generic_async = require 'generic_async_test'

local statuses = busted.run_internal_test(function()
  local ev = require 'ev'
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

