local class = require('pl.class')
local context = class()
package.loaded['busted.context'] = context  -- pre-set to prevent require loops

local test_class        = require('busted.test')
local setup_class       = require('busted.setup')
local before_each_class = require('busted.before_each')
local after_each_class  = require('busted.after_each')
local teardown_class    = require('busted.teardown')

-- instance initialization
function context:_init(desc)
  assert(desc, "Must provide a context description")
  local e = function() end
  self.parent = nil                       -- parent context, or nil if root-context
  self.setup = setup_class(e)             -- step obj containing setup procedure
  self.before_each = before_each_class(e) -- step obj containing before_each
  self.after_each = after_each_class(e)   -- step obj containing after_each
  self.teardown = teardown_class(e)       -- step obj containing teardown procedure
  self.list = {}                          -- list with test and context objects, in execution order
  self.description = desc                 -- textual description
  self.count = 0                          -- number of tests in context
  self.cumulative_count = 0               -- number of tests, including nested contexts
  self.started = false                    -- has execution started
  self.finished = false                   -- has execution been completed
  self.loop = nil                         -- contains the loop table to be used
end

-- executes context, starts with setup, then tests and nested describes, end with teardown
function context:execute(context_complete_cb)
  assert(context:class_of(self), "expected self to be a context class")
  
  local function on_teardown_complete()
    -- all is done, so call final callback to exit this context
    self.finished = true
    return context_complete_cb()
  end
  
  local index = 0
  local function do_next_step()
    index = index + 1
    if index > #self.list then
      -- list was completed, move on to teardown
      return self.teardown:execute(on_teardown_complete)
    end
    -- execute step
    local step = self.list[index]
    if not step.started then
      -- wasn't started yet, so start now
      return step:execute(do_next_step)
    elseif step.finished then
      -- already marked as started and completed, so move to next
      return do_next_step()
    else
      error("Current step, at index "..index.." of context '"..self.desc.."' was started, but not completed, so execution shouldn't be here")
    end
  end
  
  -- prepare for execution
  self.loop = self.loop or (self.parent or {}).loop or require('busted.loop.default')
  self.started = true
  -- start chain by executing setup
  return self.setup:execute(do_next_step)
end

-- mark all tests and sub-context as failed with a specific status
-- used for failing setup steps, marking everything underneath as failed
-- @param status table of original failing test
function context:mark_failed(status)
  assert(context:class_of(self), "expected self to be a context class")
  for _, step in ipairs(self.list) do 
    step:mark_failed(status)
  end
end


-- adds a test to this context
function context:add_test(test_obj)
  assert(context:class_of(self), "expected self to be a context class")
  assert(test_class:class_of(test_obj), "Can only add test classes")
  table.insert(self.list, test_obj)
  self.count = self.count + 1
  test_obj.parent = self
  local p = self
  while p do
    p.cumulative_count = p.cumulative_count + 1
    p = p.parent
  end
end

-- adds a sub context to this context
function context:add_context(context_obj)
  assert(context:class_of(self), "expected self to be a context class")
  assert(context:class_of(context_obj), "Can only add context classes")
  table.insert(self.list, context_obj)
  context_obj.parent = self
  local p = self
  while p do
    p.cumulative_count = p.cumulative_count + context_obj.cumulative_count
    p = p.parent
  end
end

-- returns the root-context of the tree this one lives in
function context:getroot()
  assert(context:class_of(self), "expected self to be a context class")
  local p = self
  while p.parent do p = p.parent end
  return p
end

-- returns the first test in the context, used to report the
-- runup error of a setup procedure in
-- note: returns nil if context contains no test (faulty situation!)
function context:firsttest()
  assert(context:class_of(self), "expected self to be a context class")
  local t = self.list[1]
  if context:class_of(t) then return t:firsttest() end
  return t
end

-- returns the last test in the context, used to report the
-- rundown error of a teardown procedure in
-- note: returns nil if context contains no test (faulty situation!)
function context:lasttest()
  assert(context:class_of(self), "expected self to be a context class")
  local t = self.list[#self.list]
  if context:class_of(t) then return t:lasttest() end
  return t
end

return context