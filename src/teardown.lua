local step_class        = require('busted.step')

-- module/object table
local teardown = step_class()
package.loaded['busted.teardown'] = teardown  -- pre-set to prevent require loops

-- instance initialization
function teardown:_init(f)
  self:super("teardown handler", f)   -- initialize ancestor; step object
  self.type = "teardown"
end

-- registers a teardown error properly
function teardown:after_execution(after_complete_cb)
  assert(teardown:class_of(self), "expected self to be a teardown class")
  if self.status.type ~= "success" then
    -- if teardown failed, set error in last test, but only if it doesn't already have an error
    self.parent:lasttest():mark_failed({
        type = self.status.type,
        trace = self.status.trace,
        err = "Test succeeded, but the 'teardown' method of context '" .. self.parent.description.."' failed: " .. tostring(self.teardown.status.err)
      }, true)  -- force overwriting existing success data
  end
  -- call ancestor method
  return self:base("after_execution", after_complete_cb)
end
