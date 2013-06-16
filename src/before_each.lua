local step_class        = require('busted.step')

-- module/object table
local before_each = step_class()
package.loaded['busted.before_each'] = before_each  -- pre-set to prevent require loops

-- instance initialization
function before_each:_init(f)
  self:super("before_each handler", f)   -- initialize ancestor; step object
  self.type = "before_each"
end

-- added 'copied_error' property
function before_each:reset()
  assert(before_each:class_of(self), "expected self to be a before_each class")
  self:base("reset")          -- call ancestor
  self.copied_error = nil     -- if set, it copied the error from an before_each upstream, so this one never got executed
end

-- Execute the entire before_each chain
function before_each:before_execution(before_complete_cb)
  local function check_error()
    if self.parent.parent.before_each.status.type ~= "success" then
      self:mark_failed({
          type = self.parent.parent.after_each.status.type,
          err = self.parent.parent.after_each.status.err,
          trace = self.parent.parent.after_each.status.trace,
        }, true)
      self.copied_error = true -- indicate we copied this error and the related after_each should not run
    end
    return before_complete_cb()
  end
  
  if self.parent ~= self.parent:getroot() then
    -- not in root-context, so must first call parent before_each
    return self.parent.parent.before_each:execute(check_error)
  else
    return before_complete_cb()
  end
end

