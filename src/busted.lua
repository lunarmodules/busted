-- busted maock up with async support
require'pl' -- for pretty.write table formating
assert = require'luassert'
spy = require('luassert.spy')
mock = require('luassert.mock')
stub = require('luassert.stub')
-- Load default language pack

busted = {}
busted._COPYRIGHT   = "Copyright (c) 2012 Olivine Labs, LLC."
busted._DESCRIPTION = "A unit testing framework with a focus on being easy to use."
busted._VERSION     = "Busted 1.4"
require('busted.languages.en')
--module('busted',package.seeall)
local assert_call = getmetatable(assert.is_truthy).__call
local push = table.insert
local root_context = {parents = {}}
local tests = {}
local done = {}
local started = {}
local last_test = 1
local next_test
next_test = function()
   if #done < #tests then
      if not done[last_test] and not started[last_test] then
         local test = tests[last_test]
         if test.context then
            if test.context.before and not test.context.before_done then
               test.context.before(
                  function()
                     test.context.before_done = true
                     next_test()
                  end)
               return
            end
            if test.context.before_each and test.context.last_before ~= last_test then
               test.context.last_before = last_test            
               test.context.before_each(next_test)
               return
            end
         end
         test.status = {
            description = test.name,
            info = test.info,
            trace = ''
         }
         test.info = nil
         local new_env = {}
         setmetatable(new_env,{__index = _G})
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
                  print(test.status.type)
                  test.status.err = results[2]
               end
            end
         end
         -- not sure if this is needed yet...
         -- new_env.pcall = function(...)
         --    local ok,err = pcall(...)
         --    if not ok then
         --       test.status.type = 'failure'
         --       test.status.err = err
         --    end
         -- end 

         setfenv(test.f,new_env)
         local done = function()
            done[last_test] = true
            last_test = last_test + 1
            next_test()
         end
         started[last_test] = true
         local ok,err = pcall(test.f,done)
         if not ok then
            if type(err) == "table" then
               err = pretty.write(err)
            end
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



local report = function()
   for _,test in ipairs(tests) do
      print(pretty.write(test.status))
   end
end

busted.reset = function()
   current_context = root_context
   tests = {}
   done = {}
   started = {}
   last_test = 1
end

busted.run = function(options)
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
      if test.status.type ~= 'success' and not test.status.err then
         test.status.type = 'failure'
         test.status.err = 'No assertions made'
         test.status.trace = ''
      end
      push(statuses,test.status)
   end
   ms = os.clock() - ms
   return options.output.formatted_status(statuses, options, ms), 0
end

it = busted.it
describe = busted.describe
before = busted.before
before_each = busted.before_each

return busted