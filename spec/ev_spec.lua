-- Runs internally an ev async test and checks the returned statuses.

if not pcall(require, "ev") then
  describe("Testing ev loop", function()
      pending("The 'ev' loop was not tested because 'ev' isn't installed")
    end)
else
  
  local generic_async = require 'generic_async_test'
  local ev = require 'ev'
  local loop = ev.Loop.default
  
  local statuses = busted.run_internal_test(function()
      
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
    it('this should timeout',function(done)
      settimeout(0.01)
      ev.Timer.new(async(function() done() end),0.1):start(loop)
    end)
      
    it('this should not timeout',function(done)
      settimeout(0.1)
      ev.Timer.new(async(function() done() end),0.01):start(loop)
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
  
end
