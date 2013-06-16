local step_class        = require('busted.step')

-- module/object table
local after_each = step_class()
package.loaded['busted.after_each'] = after_each  -- pre-set to prevent require loops

-- instance initialization
function after_each:_init(f)
  self:super("after_each handler", f)   -- initialize ancestor; step object
  self.type = "after_each"
end


function after_each:before_execution(before_complete_cb)
  if self.parent.before_each.copied_error then
    -- companion before_each did not run, so neither should we
    self.status.started = true
    self.status.finished = true
  end
  return before_complete_cb()
end

-- Execute the entire after_each chain
function after_each:after_execution(after_complete_cb)
  
  local function check_error()
    if self.parent.parent.after_each.status.type ~= "success" and self.status.type == "success" then
      self:mark_failed({
          type = self.parent.parent.after_each.status.type,
          err = self.parent.parent.after_each.status.err,
          trace = self.parent.parent.after_each.status.trace,
        }, true)
    end
    return after_complete_cb()
  end
  
  if self.parent ~= self.parent:getroot() then
    -- not in root-context, so must call parent after_each
    return self.parent.parent.after_each:execute(check_error)
  else
    return after_complete_cb()
  end
end

