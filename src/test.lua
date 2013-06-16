local step_class        = require('busted.step')

-- module/object table
local test = step_class()
package.loaded['busted.test'] = test  -- pre-set to prevent require loops

-- instance initialization
function test:_init(f)
  self:super("test handler", f)   -- initialize ancestor; step object
  self.type = "test"
end

-- added 'flushed' property
function test:reset()
  assert(test:class_of(self), "expected self to be a before_each class")
  self:base("reset")          -- call ancestor
  self.flushed = nil          -- if thruthy, then output was already written
end


-- execute before_each chain here
function test:before_execution(before_complete_cb)
  
  local function error_check()
    -- if an error in before_each, then copy it into test and do not exeucte test
    if self.parent.before_each.status.type ~= "success" then
      self:mark_failed({
          type = parent.before_each.status.type,
          err = parent.before_each.status.err,
          trace = parent.before_each.status.trace,
        }, true)
    end
    return before_complete_cb()
  end
  
  return parent.before_each:execute(error_check)
end

-- execute after_each chain here
function test:after_execution(after_complete_cb)
  
  local function error_check()
    -- if an error in after_each, then copy it into test and do not exeucte test
    if self.parent.after_each.status.type ~= "success" then
      self:mark_failed({
          type = parent.after_each.status.type,
          err = parent.after_each.status.err,
          trace = parent.after_each.status.trace,
        }, true)
    end
    return after_complete_cb()
  end
  
  return parent.after_each:execute(error_check)
end

-- flush test results to the outputter
-- because the errors of a teardown chain are reported in the last test before it
-- a test cannot write its output upon completion.
-- the context object should call flush when the test output can no longer
-- be altered by the teardown chain procedure
function test:flush_results()
  if not self.flushed then
    -- TODO: actually write output
  end
  self.flushed = true
end
