local step_class        = require('busted.step')

-- module/object table
local setup = step_class()
package.loaded['busted.setup'] = setup  -- pre-set to prevent require loops

-- instance initialization
function setup:_init(f)
  self:super("setup handler", f)   -- initialize ancestor; step object
  self.type = "setup"
end

-- registers a setup error properly
function setup:after_execution(after_complete_cb)
  assert(setup:class_of(self), "expected self to be a setup class")
  if self.status.type ~= "success" then
    -- if setup failed, set error in first test
    self.parent:firsttest():mark_failed({
        type = self.status.type,
        trace = self.status.trace,
        err = "Test not executed, the 'setup' method of context '" .. self.parent.description.."' failed: " .. tostring(self.teardown.status.err)
      }, true) -- force overwriting existing success status
    -- update all other test underneith as well
    self.parent:mark_failed({
        type = self.setup.status.type,
        trace = "",
        err = "Test not executed, due to failing 'setup' chain",
      }) 
    end
  end
  -- call ancestor method
  return self:base("after_execution", after_complete_cb)
end