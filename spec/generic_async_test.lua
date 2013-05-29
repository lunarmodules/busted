
local pl = require'pl.pretty'

local setup_async_tests = function(yield,loopname,create_timer)
  describe(
    loopname..' test suite',
    function()
      local before_each_count = 0
      local before_called
      setup(
        function(done)
          yield(async(
              function()
                before_called = true
                done()
            end))
          
        end)
      
      before_each(
        function(done)
          yield(async(
              function()
                before_each_count = before_each_count + 1
                done()
            end))
        end)
      
      it(
        'should async succeed',
        function(done)
          yield(async(
              function()
                assert.is_true(before_called)
                assert.is.equal(before_each_count,1)
                done()
            end))
        end)
      
      it(
        'should async fail',
        function(done)
          yield(async(
              function()
                assert.is_truthy(false)
                done()
            end))
        end)
      
      it(
        'should async fails epicly',
        function(done)
          does_not_exist.foo = 3
        end)
      
      it(
        'should succeed',
        function(done)
          done()
        end)
      
      it(
        'spies should sync succeed',
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
        'spies should async succeed',
        function(done)
          local thing = {
            greet = function()
            end
          }
          spy.on(thing, "greet")
          yield(async(
              function()
                assert.spy(thing.greet).was.called()
                assert.spy(thing.greet).was.called_with("Hi!")
                done()
            end))
          thing.greet("Hi!")
        end)
      
      describe(
        'with nested contexts',
        function()
          local before_called
          setup(
            function(done)
              yield(async(
                  function()
                    before_called = true
                    done()
                end))
            end)
          it(
            'nested async test before is called succeeds',
            function(done)
              yield(async(
                  function()
                    assert.is_true(before_called)
                    done()
                end))
            end)
        end)
      
      pending('is pending')
      
      it(
        'calling done twice fails',
        function(done)
          yield(async(
              function()
                done()
                done()
            end))
        end)
      
      if create_timer then
        it(
          'wait_ordered succeeds',
          function(done)
            done:wait_ordered('t1','t2','t3')
            create_timer(0.001,async(function()
                  done('t1')
              end))
            create_timer(0.002,async(function()
                  done('t2')
              end))
            create_timer(0.003,async(function()
                  done('t3')
              end))
          end)
        
        it(
          'wait_ordered fails with wrong order',
          function(done)
            done:wait_ordered('t1','t2','t3')
            create_timer(0.001,async(function()
                  done('t1')
              end))
            create_timer(0.002,async(function()
                  done('t3')
              end))
            create_timer(0.003,async(function()
                  done('t2')
              end))
          end)
        
        it(
          'wait_ordered fails with double token',
          function(done)
            done:wait_ordered('t1','t2','t3')
            create_timer(0.001,async(function()
                  done('t1')
              end))
            create_timer(0.002,async(function()
                  done('t3')
              end))
            create_timer(0.003,async(function()
                  done('t3')
              end))
          end)
        
        it(
          'wait_unordered succeeds',
          function(done)
            done:wait_unordered('t1','t2','t3')
            create_timer(0.001,async(function()
                  done('t1')
              end))
            create_timer(0.002,async(function()
                  done('t3')
              end))
            create_timer(0.003,async(function()
                  done('t2')
              end))
          end)
        
        it(
          'wait_unordered fails with unknown token',
          function(done)
            done:wait_unordered('t1','t2','t3')
            create_timer(0.001,async(function()
                  done('t1')
              end))
            create_timer(0.002,async(function()
                  done('t3')
              end))
            create_timer(0.003,async(function()
                  done('t5')
              end))
          end)
      end
      
      
    end)
end

local describe_statuses = function(statuses,print_statuses)
  if print_statuses then
    print('---------- STATUSES ----------')
    print(pretty.write(statuses))
    print('------------------------------')
  end
  
  describe(
    'Test statuses',
    function()
      it(
        'type is correct',
        function()
          for i,status in ipairs(statuses) do
            local type = status.type
            assert.is_truthy(type == 'failure' or type == 'success' or type == 'pending')
            local succeed = status.description:match('succeed')
            local fail = status.description:match('fail')
            local pend = status.description:match('pend')
            local count = 0
            if succeed then
              count = count + 1
            end
            if fail then
              count = count + 1
            end
            if pend then
              count = count + 1
            end
            if not succeed and not pend and not fail then
              print('STATUS',status.description)
            end
            assert.equal(count,1)
            if succeed then
              assert(status.type == 'success', status.description..' '..pl.write(status))
            elseif fail then
              assert(status.type == 'failure', status.description..' '..pl.write(status))
            elseif pend then
              assert(status.type == 'pending', status.description..' '..pl.write(status))
            end
          end
        end)
      
      it(
        'info is correct',
        function()
          for i,status in ipairs(statuses) do
            assert.is_truthy(status.info.linedefined)
            assert.is_truthy(status.info.source:match('generic_async_test%.lua'))
            assert.is_truthy(status.info.short_src:match('generic_async_test%.lua'))
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
      
      it(
        'calling done twice fails is reported correctly',
        function()
          for i,status in ipairs(statuses) do
            if status.description:match('.*done.*twice') then
              assert.is_truthy(status.err:match('.*First called from.*stack traceback'))
              return
            end
          end
          assert.is_falsy('twice report failed')
        end)
      
    end)
end

return {
  setup_tests = setup_async_tests,
  describe_statuses = describe_statuses
}
