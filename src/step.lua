-- base class for test execution steps. The classes;
-- setup, before_each, test, after_each and teardown
-- derive from this one

local wrap_done = require('busted.done').new
local moon = require('busted.moon')
local pretty = require('pl.pretty')
local class = require('pl.class')
local busted = require('busted.core')

-- module/object table
local step = class()
package.loaded['busted.step'] = step  -- pre-set to prevent require loops

-- wraps test callbacks (it, for_each, setup, etc.) to ensure that sync
-- tests also call the `done` callback to mark the test/step as complete
local syncwrapper = function(self, f)
  return function(done_cb, ...)
    self.step_is_async = nil
    f(done_cb, ...)
    if not self.step_is_async then
      -- async function wasn't called, so it is a sync test/function
      -- hence must call it ourselves
      done_cb()
    end
  end
end

-- instance initialization
function step:_init(desc, f)
  assert(desc, "Must provide a description")
  assert(type(f) == "function", "Must provide a step function")
  self.parent = nil                       -- parent context, or nil if root-context
  self.f = f                              -- function containing the test step
  self.description = desc                 -- textual description
  self.type = "step"                      -- either; step (only as baseclass, not used), setup, teardown, test, before/after_each
  self:reset()
end

-- reset step status, required for before_each/after_each as they will run multiple times
function step:reset()
  assert(step:class_of(self), "expected self to be a step class")
  self.started = false                    -- has execution started
  self.finished = false                   -- has execution been completed
  self.status = {                         -- contains the results of the step
    type = 'success',                     -- result, either 'success' or 'failure'
    err = nil,                            -- error message in case of failure
    trace = nil,                          -- stacktrace in case of a failure
  }
  self.done_trace = nil                   -- first stacktrace of 'done' callback to track multiple calls
  self.step_is_async = nil                -- detection of step being sync/async
  self.loop = self.parent.loop
  if self.timer then                      -- timer for the execution step
    self.timer:stop()
    self.timer = nil
  end
end

function step:execute(step_complete_cb)
  assert(step:class_of(self), "expected self to be a step class")
  
  local after_complete = function()
    self.finished = true
    return step_complete_cb()
  end
  
  local execute_complete = function()
    return self:after_execution(after_complete)
  end
  
  local before_complete = function()
    if self.status.type == "success" then
      return self:_execute(execute_complete)
    else
      return execute_complete() -- error occured, so skip execution and go to after handler
    end
  end
  
  -- prepare for execution
  self:reset()
  self.started = true
  -- start chain by executing before handler
  return self:before_execution(before_complete)
end

-- should execute the core step and store the result in self.status
function step:_execute(execute_complete_cb)
  assert(step:class_of(self), "expected self to be a step class")
  
  local done = function()
    if self.timer then
      self.timer:stop()
      self.timer = nil
    end
    
    if self.done_trace then
      if self.status.type == "success" then
        local _, stack_trace = moon.rewrite_traceback(nil, debug.traceback("", 2))
        self.status.err = 'test already "done":"'..self.description..'"' 
        self.status.err = self.status.err..'. First called from '..self.done_trace
        self.status.type = 'failure'
        self.status.trace = stack_trace
      end
      return -- no callbacks here, we're already called on first call to `done`
    end

    settimeout = nil   -- remove global    
    self.finished = true
    -- keep done trace for easier error location when called multiple times
    local _, done_trace = moon.rewrite_traceback(nil, debug.traceback("", 2))
    self.done_trace = pretty.write(done_trace)

    return execute_complete_cb()
  end

  if self.loop.create_timer then
    -- create a global `settimeout`
    settimeout = function(timeout)
      if self.timer then self.timer:stop() end
      self.timer = self.loop.create_timer(timeout,function()
        if not self.done_trace then
          self.status.type = 'failure'
          self.status.trace = ''
          self.status.err = 'test timeout elapsed ('..timeout..'s)'
          return done()
        end
      end)
    end
  else
    -- this loop doesn't support timers
    settimeout = nil
  end

  local ok, err = (self.loop.pcall or pcall)(syncwrapper(self, self.f), wrap_done(done)) 
  
  if ok then
    -- test returned, set default timer if one hasn't been set already
    if settimeout and not self.timer and not self.finished then
      settimeout(busted.defaulttimeout)
    end
    return          -- return, waiting for `done` to be called
  else
    if type(err) == "table" then
      err = pretty.write(err)
    end

    local trace = debug.traceback("", 2)
    err, trace = moon.rewrite_traceback(err, trace)

    self.status.type = 'failure'
    self.status.trace = trace
    self.status.err = err
    return done()   -- an error so we're complete and can call 'done' ourselves
  end
end

-- will be called before the step is executed
-- override in descendant class to perform the before_each steps
-- Any errors should be stored in self.status
function step:before_execution(before_complete_cb)
  assert(step:class_of(self), "expected self to be a step class")
  return before_complete_cb()
end

-- will be called after the step has been executed
-- override in descendant class to perform the after_each steps
-- Any errors should be stored in self.status, ONLY if it does not yet contain an error
function step:after_execution(after_complete_cb)
  assert(step:class_of(self), "expected self to be a step class")
  return after_complete_cb()
end

-- marks **UNFINISHED** test as failed, existing errors will never be overwritten.
-- @param status table of original failing test
-- @force if truthy then any existing success of a **FINISHED** value will be overwritten by the status
function step:mark_failed(status, force)
  assert(step:class_of(self), "expected self to be a step class")
  if (not self.finished) or force then
    self.started = true
    self.finished = true
    self.status.type = status.type
    self.status.err = status.err
    self.status.trace = status.trace
  end
end
