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

local assert_call = getmetatable(assert.is_truthy).__call
local globals = _G
local push = table.insert
local root_context = {parents = {}}
local tests = {}
local done = {}
local started = {}
local last_test = 1
local next_test
local options
next_test = function()
   if #done < #tests then
      if not done[last_test] and not started[last_test] then
         local test = tests[last_test]
         if test.context.before and not test.context.before_started then
            test.context.before_started = true
            test.context.before(
               function()
                  test.context.before_done = true
                  next_test()
               end)
            return
         end
         if test.context.before_each and not test.context.before_each_started then
            test.context.before_each_started = true            
            test.context.before_each(
               function()
                  test.context.before_each_done = true
                  next_test()
               end)
            return
         end
         
         if test.context.before and not test.context.before_done then
            return
         end
         test.context.before_started = nil
         test.context.before_done = nil
         if test.context.before_each and not test.context.before_each_done then
            return
         end
         test.context.before_each_started = nil
         test.context.before_each_done = nil

         test.status = {
            description = test.name,
            info = test.info,
            trace = ''
         }
         test.info = nil
         local new_env = {}
         setmetatable(new_env,{__index = globals})
         -- this part is nasty!
         -- intercept all calls to luasser states / proxies.
         -- uses much of internal knowlage of luassert!!!!
         -- the metatable of is_truthy is the same as for other
         -- luasserts.
         getmetatable(new_env.assert.is_truthy).__call = function(...)            
            local results = {pcall(assert_call,...)}
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
                  test.status.trace = debug.traceback("", 2)
                  test.status.type = 'failure'
                  test.status.err = results[2]
               end
            end
         end
         setfenv(test.f,new_env)
         local done = function()
            done[last_test] = true
            last_test = last_test + 1
            if test.status.type ~= 'success' and not test.status.err then
               test.status.type = 'failure'
               test.status.err = 'No assertions made'
               test.status.trace = test.status.info.source..':'..test.status.info.linedefined
            end
            if not options.debug and not options.defer_print then
               options.output.currently_executing(test.status, options)
            end
            next_test()
         end
         started[last_test] = true
         local ok,err = pcall(test.f,done)
         if not ok then
            if type(err) == "table" then
               err = pretty.write(err)
            end
            test.status.type = 'failure'
            test.status.trace = debug.traceback("", 2)
            test.status.err = err
            done()
         end
      end
   end
end

local current_context
busted.describe = function(desc,more)   
   local parents = {}
   for i,parent in ipairs(current_context.parents) do
      parents[i] = parent
   end   
   push(parents,current_context)
   local context = {
      desc = desc,
      parents = parents
   }   
   current_context = context
   more()
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

busted.it = function(name,sync_test,async_test)
   local test = {}
   test.context = current_context
   test.name = name
   local debug_info
   if async_test then
      debug_info = debug.getinfo(async_test)
      test.f = async_test
   else
      debug_info = debug.getinfo(sync_test)
      -- make sync test run async
      test.f = function(done)
         setfenv(sync_test,getfenv(1))
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
   current_context = root_context
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
before_each = busted.before_each

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