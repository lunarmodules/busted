-- Runs internally an ev async test and checks the returned statuses.
--
--
package.path = './?.lua;'..package.path
local ev = require'ev'
local loop = ev.Loop.default
require'busted'

local eps = 0.000000000001

describe(
   'All async in this context',
   function()
      local before_each_count = 0
      local before_called
      before(
         async, 
         function(done)
            ev.Timer.new(
               function()
                  assert.is_falsy(before_called)
                  before_called = true
                  done()
               end,eps):start(loop)
         end)

      before_each(
         async,
         function(done)
            ev.Timer.new(
               function()
                  before_each_count = before_each_count + 1
                  done()
               end,eps):start(loop)
         end)      
      
      it(
         'order 1 should async succeed',
         async,
         function(done)
            local timer = ev.Timer.new(
               function()
                  assert.is_true(before_called)
                  assert.is.equal(before_each_count,1)
                  done()
               end,eps)
            timer:start(loop)
         end)

      it(
         'order 2 should async fail',
         async,
         function(done)
            local timer = ev.Timer.new(
               function()
                  assert.is_truthy(false)
                  done()
               end,eps)
            timer:start(loop)
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
            local timer = ev.Timer.new(
               function()
                  assert.spy(thing.greet).was.called()
                  assert.spy(thing.greet).was.called_with("Hi!")
                  done()
               end,eps)                  
            thing.greet("Hi!")
            timer:start(loop)
         end)

      describe(
         'with nested contexts',
         function()
            local before_called
            before(
               async,
               function(done)
                  ev.Timer.new(
                     function()
                        before_called = true
                        done()
                     end,eps):start(loop)                  
               end)
            it(
               'order 7 nested async test before is called succeeds',
               async,
               function(done)
                  local timer = ev.Timer.new(
                     function()
                        assert.is_true(before_called)
                        done()
                     end,eps)
                  timer:start(loop)
               end)
        end)
   end)

local options = {
   debug = true,
   loop = 'ev',
   loop_arg = loop
} 

local statuses = busted.run(options)

-- local print_statuses = true
if print_statuses then
   print('---------- STATUSES ----------')
   print(pretty.write(statuses))
   print('------------------------------')
end

busted.reset()

describe(
   'Test statuses of ev loop',
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
               assert.is_truthy(status.info.linedefined)
               assert.is_truthy(status.info.source:match('ev_spec%.lua'))
               assert.is_truthy(status.info.short_src:match('ev_spec%.lua'))
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