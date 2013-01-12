package.path = './?.lua;'..package.path
local ev = require'ev'
local loop = ev.Loop.default
require'busted'

describe(
   'All async in this context',
   function()
      before(
         async, 
         function(done)
            local count = 0
            ev.Timer.new(
               function(loop,io)
                  count = count + 1
                  print('before',count)
                  if count == 3 then
                     print('lets start')
                     io:stop(loop)
                     done()
                  end
               end,0.1,0.1):start(loop)
         end)

      before_each(
         async,
         function(done)
            ev.Timer.new(
               function()                  
                  print('before_each')
                  done()
               end,0.01):start(loop)
         end)      
      
      it(
         'async test',
         async,
         function(done)
            local timer = ev.Timer.new(
               function()
                  assert.is_truthy(true)
                  done()
               end,0.2)
            timer:start(loop)
         end)

      it(
         'async test 2',
         async,
         function(done)
            local timer = ev.Timer.new(
               function()
                  assert.is_truthy(false)
                  assert.is_truthy(true)
                  done()
               end,0.2)
            timer:start(loop)
         end)

      it(
         'should epic fail',
         async,
         function(done)
            does_not_exist.foo = 3            
         end)

      it(
         'spies work',
         function()
            local thing = {
               greet = function()
               end
            }            
            print('SPY',spy)
            for k,v in pairs(spy) do
               print(k,v)
            end
            spy.on(thing, "greet")
            thing.greet("Hi!")
            
            assert.spy(thing.greet).was.called()
            assert.spy(thing.greet).was.called_with("Hi!")
         end)

      describe(
         'with nested contexts',
         function()
            before(
               async,
               function(done)
                  print('before in nested')
                  done()
               end)
            it(
               'a nested test',
               async,
               function(done)
                  print('NESTED TEST')
                  local timer = ev.Timer.new(
                     function()
                        print('NESTED TEST BAKS')
                        assert.is_truthy('horst')
                        assert.is_truthy(true)
                        assert.is_truthy(true)
                        done()
                     end,0.2)
                  timer:start(loop)
               end)
        end)
   end)

return 'ev',loop