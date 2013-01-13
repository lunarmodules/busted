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

busted.reset()
busted.describe_statuses(statuses,'ev_spec%.lua')
