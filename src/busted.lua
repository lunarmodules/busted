require'pl' -- for pretty.write table formating
assert = require'luassert'
spy = require('luassert.spy')
mock = require('luassert.mock')
stub = require('luassert.stub')

busted = {}
busted._COPYRIGHT   = "Copyright (c) 2012 Olivine Labs, LLC."
busted._DESCRIPTION = "A unit testing framework with a focus on being easy to use."
busted._VERSION     = "Busted 1.4"

-- Load default language pack
require('busted.languages.en')

local assert_proxy_call = getmetatable(assert.is_truthy).__call
local assert_call = getmetatable(assert).__call
local globals = _G
local push = table.insert
local tests = {}
local done = {}
local started = {}
local last_test = 1
local options

local step = function(...)
   local steps = {...}
   if #steps == 1 and type(steps[1]) == 'table' then
      steps = steps[1]
   end
   local i = 0
   local next
   next = function()
      i = i + 1
      local step = steps[i]
      if step then
         step(next)
      end
   end
   next()
end

local next_test
next_test = function()
   if #done == #tests then
      return
   end
   if not started[last_test] then
      started[last_test] = true
      local test = tests[last_test]
      local steps = {}
      local execute_test = function(next)
         test.status = {
            description = test.name,
            info = test.info,
            trace = ''
         }         
         -- this part is a bit nasty!
         -- intercept all calls to luassert states / proxies.
         -- uses much of internal knowlage of luassert!!!!
         -- the metatable of is_truthy is the same as for other
         -- luasserts.
         getmetatable(assert.is_truthy).__call = function(...)
            local results = {pcall(assert_proxy_call,...)}
            local args = {...}
            local is_proxy = true
            -- ducktype if this is an assertion 'result' and not a proxy
            for k,v in pairs(args[1] or {}) do
               if k == 'positive_message' or k == 'negative_message' then
                  is_proxy = false
               end
            end
            if is_proxy then
               return unpack(results,2)
            else
               if results[1] and not test.status.type then
                  test.status.type = 'success'
               elseif not results[1] and test.status.type ~= 'failure' then
                  -- the error message and traceback are always caused
                  -- by the first failed assertion
                  test.status.trace = debug.traceback("", 2)
                  test.status.type = 'failure'
                  test.status.err = results[2]
                  -- dont call done() here but continue test execution
                  -- uncaught errors following, will be catched in pcall(test.f,done)
               end
            end
         end
         getmetatable(assert).__call = function(...)
            local results = {pcall(assert_call,...)}
            if results[1] and not test.status.type then
               test.status.type = 'success'
            elseif not results[1] and test.status.type ~= 'failure' then
               test.status.trace = debug.traceback("", 2)
               test.status.type = 'failure'
               test.status.err = results[2]
            end
         end
         local done = function()
            done[last_test] = true
            if test.status.type ~= 'success' and not test.status.err then
               test.status.type = 'failure'
               test.status.err = 'No assertions made'
               test.status.trace = test.status.info.source..':'..test.status.info.linedefined
            end
            if not options.debug and not options.defer_print then
               options.output.currently_executing(test.status, options)
            end
            test.context:decrement_test_count()
            next()
         end
         local ok,err = pcall(test.f,done)
         if not ok then
            if not test.status.err or test.status.type ~= 'failure' then
               if type(err) == "table" then
                  err = pretty.write(err)
               end
               test.status.type = 'failure'
               test.status.trace = debug.traceback("", 2)
               test.status.err = err
            end
            done()
         end
      end

      local check_before = function(context)
         if context.before then
            local execute_before = function(next)
               context.before(
                  function()
                     context.before = nil
                     next()
                  end)
            end
            push(steps,execute_before)
         end
      end

      local parents = test.context.parents

      for p=1,#parents do
         check_before(parents[p])
      end

      check_before(test.context)

      for p=1,#parents do
         if parents[p].before_each then
            push(steps,parents[p].before_each)
         end
      end

      if test.context.before_each then
         push(steps,test.context.before_each)
      end

      push(steps,execute_test)

      if test.context.after_each then
         push(steps,test.context.after_each)
      end

      local post_test = function(next)
         local post_steps = {}
         local check_after = function(context)
            if context.after then
               if context:all_tests_done() then
                  local execute_after = function(next)
                     context.after(
                        function()
                           context.after = nil
                           next()
                        end)
                  end
                  push(post_steps,execute_after)
               end
            end
         end

         check_after(test.context)

         for p=#parents,1,-1 do
            if parents[p].after_each then
               push(post_steps,parents[p].after_each)
            end
         end

         for p=#parents,1,-1 do
            check_after(parents[p])
         end

         local forward = function(next)
            last_test = last_test + 1
            next_test()
            next()
         end
         push(post_steps,forward)
         step(post_steps)
      end
      push(steps,post_test)
      step(steps)
   end
end

local create_context = function(desc)
   local context = {
      desc = desc,
      parents = {},
      test_count = 0,
      increment_test_count = function(self)
         self.test_count = self.test_count + 1
         for _,parent in ipairs(self.parents) do
            parent.test_count = parent.test_count + 1
         end
      end,
      decrement_test_count = function(self)
         self.test_count = self.test_count - 1
         for _,parent in ipairs(self.parents) do
            parent.test_count = parent.test_count - 1
         end
      end,
      all_tests_done = function(self)
         return self.test_count == 0
      end,
      add_parent = function(self,parent)
         push(self.parents,parent)
      end
   }
   return context
end

local current_context
busted.describe = function(desc,more)
   local context = create_context(desc)
   for i,parent in ipairs(current_context.parents) do
      context:add_parent(parent)
   end
   context:add_parent(current_context)
   local old_context = current_context
   current_context = context
   more()
   current_context = old_context
end

busted.before = function(sync_before,async_before)
   if async_before then
      current_context.before = async_before
   else
      current_context.before = function(done)
         sync_before()
         done()
      end
   end
end

busted.before_each = function(sync_before,async_before)
   if async_before then
      current_context.before_each = async_before
   else
      current_context.before_each = function(done)
         sync_before()
         done()
      end
   end
end

busted.after = function(sync_after,async_after)
   if async_after then
      current_context.after = async_after
   else
      current_context.after = function(done)
         sync_after()
         done()
      end
   end
end

busted.after_each = function(sync_after,async_after)
   if async_after then
      current_context.after_each = async_after
   else
      current_context.after_each = function(done)
         sync_after()
         done()
      end
   end
end

busted.it = function(name,sync_test,async_test)
   local test = {}
   test.context = current_context
   test.context:increment_test_count()
   test.name = name
   local debug_info
   if async_test then
      debug_info = debug.getinfo(async_test)
      test.f = async_test
   else
      debug_info = debug.getinfo(sync_test)
      -- make sync test run async
      test.f = function(done)
         sync_test()
         done()
      end
   end
   test.info = {
      source = debug_info.source,
      short_src = debug_info.short_src,
      linedefined = debug_info.linedefined,
   }
   tests[#tests+1] = test
end

busted.reset = function()
   current_context = create_context('Root context')
   tests = {}
   done = {}
   started = {}
   last_test = 1
end

busted.run = function(opts)
   options = opts
   local ms = os.clock()
   if not options.loop then
      next_test()
   elseif options.loop == 'ev' then
      local loop = options.loop_arg
      local ev = require'ev'
      ev.Timer.new(next_test,0.0001):start(loop)
      loop:loop()
   elseif options.loop == 'copas' then
      local copas = require'copas'
      copas.addthread(
         function()
            repeat
               next_test()
               copas.step(0)
            until #done == #tests
         end)
   end
   local statuses = {}
   for _,test in ipairs(tests) do
      push(statuses,test.status)
   end
   ms = os.clock() - ms
   if options.debug then
      return statuses
   else
      return options.output.formatted_status(statuses, options, ms), 0
   end
end

it = busted.it
describe = busted.describe
before = busted.before
after = busted.after
setup = busted.before
teardown = busted.after
before_each = busted.before_each
after_each = busted.after_each

-- only for internal testing
busted.setup_async_tests = function(yield,loopname)
   describe(
      loopname..' test suite',
      function()
         local before_each_count = 0
         local before_called
         before(
            async,
            function(done)
               yield(
                  function()
                     before_called = true
                     done()
                  end)
            end)

         before_each(
            async,
            function(done)
               yield(
                  function()
                     before_each_count = before_each_count + 1
                     done()
                  end)
            end)

         it(
            'order 1 should async succeed',
            async,
            function(done)
               yield(
                  function()
                     assert.is_true(before_called)
                     assert.is.equal(before_each_count,1)
                     done()
                  end)
            end)

         it(
            'order 2 should async fail',
            async,
            function(done)
               yield(
                  function()
                     assert.is_truthy(false)
                     done()
                  end)
            end)

         it(
            'order 3 should async fails epicly',
            async,
            function(done)
               does_not_exist.foo = 3
            end)

         it(
            'order 4 should async have no assertions and fails thus',
            async,
            function(done)
               done()
            end)

         it(
            'order 5 spies should sync succeed',
            function()
               assert.is.equal(before_each_count,5)
               local thing = {
                  greet = function()
                  end
               }
               spy.on(thing, "greet")
               thing.greet("Hi!")
               assert.spy(thing.greet).was.called()
               assert.spy(thing.greet).was.called_with("Hi!")
            end)

         it(
            'order 6 spies should async succeed',
            async,
            function(done)
               local thing = {
                  greet = function()
                  end
               }
               spy.on(thing, "greet")
               yield(
                  function()
                     assert.spy(thing.greet).was.called()
                     assert.spy(thing.greet).was.called_with("Hi!")
                     done()
                  end)
               thing.greet("Hi!")
            end)

         describe(
            'with nested contexts',
            function()
               local before_called
               before(
                  async,
                  function(done)
                     yield(
                        function()
                           before_called = true
                           done()
                        end)
                  end)
               it(
                  'order 7 nested async test before is called succeeds',
                  async,
                  function(done)
                     yield(
                        function()
                           assert.is_true(before_called)
                           done()
                        end)
                  end)
            end)
      end)
end

-- only for internal testing
busted.describe_statuses = function(statuses,print_statuses)
   if print_statuses then
      print('---------- STATUSES ----------')
      print(pretty.write(statuses))
      print('------------------------------')
   end

   describe(
      'Test statuses',
      function()
         it(
            'execution order is correct',
            function()
               for i,status in ipairs(statuses) do
                  local order = status.description:match('order (%d+)')
                  assert.is.equal(tonumber(order),i)
               end
            end)

         it(
            'type is correct',
            function()
               for i,status in ipairs(statuses) do
                  assert.is_truthy(status.type == 'failure' or status.type == 'success')
                  local succeed = status.description:match('succeed')
                  local fail = status.description:match('fail')
                  assert.is_falsy(succeed and fail)
                  if succeed then
                     assert.is.equal(status.type,'success')
                  elseif fail then
                     assert.is.equal(status.type,'failure')
                  end
               end
            end)

         it(
            'info is correct',
            function()
               for i,status in ipairs(statuses) do
                  --  print(pretty.write(status))
                  assert.is_truthy(status.info.linedefined)
                  assert.is_truthy(status.info.source:match('busted%.lua'))
                  assert.is_truthy(status.info.short_src:match('busted%.lua'))
               end
            end)

         it(
            'provides "err" for failed tests',
            function()
               for i,status in ipairs(statuses) do
                  if status.type == 'failure' then
                     assert.is.equal(type(status.err),'string')
                     assert.is_not.equal(#status.err,0)
                  end
               end
            end)

         it(
            'provides "traceback" for failed tests',
            function()
               for i,status in ipairs(statuses) do
                  if status.type == 'failure' then
                     assert.is.equal(type(status.trace),'string')
                     assert.is_not.equal(#status.trace,0)
                  end
               end
            end)

      end)
end

return busted