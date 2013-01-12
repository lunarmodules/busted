package.path = './?.lua;'..package.path
local copas = require'copas'
local socket = require'socket'
require'busted'

local port = 19281
describe(
   'When someone connects to echo server',
   function()
      before(
         async,
         function(done)
            copas.addserver(
               socket.bind('*',port),
               function(skt)
                  print('new client')
                  while true do
                     local data = copas.receive(skt)
                     if not data then
                        return
                     end
                     copas.send(skt,data..'\n')               
                  end
               end)
            done()
         end)

      before_each(
         async,
         function(done)
            print('before each async')
            done()
         end)
      
      it(
         'sent messages and maing bad test fails',
         async,
         function(done)
            print('A')
            copas.addthread(
               function()
                  local s = socket.connect('localhost',port)
                  s:settimeout(0)
                  local client = copas.wrap(s)
                  local msg = 'HALLO'
                  client:send(msg..'\n')
                  client:receive('*l')
                  s:close()
                  assert.is_truthy(false)
                  assert.is_truthy(false)
                  print('F A')
                  done()
               end)
         end)

      it(
         'sent messages are echoed correctly',
         async,
         function(done)
            print('B')
            copas.addthread(
               function()
                  local s = socket.connect('localhost',port)
                  s:settimeout(0)
                  local client = copas.wrap(s)
                  local msg = 'HALLO'
                  client:send(msg..'\n')
                  local echoed = client:receive('*l')
                  s:close()
                  assert.is_truthy(echoed == msg)
                  print('F B')
                  done()
               end)
         end)

      it(
         'sent messages are echoed correctly with two clients',
         async,
         function(done)
            local other_finished
            copas.addthread(
               function()
                  local s = socket.connect('localhost',port)
                  s:settimeout(0)
                  local client = copas.wrap(s)
                  local msg = 'HALLO'
                  client:send(msg..'\n')
                  local echoed = client:receive('*l')
                  s:close()
                  assert.is_truthy(echoed == msg)
                  if other_finished then                     
                     done()
                  else
                     other_finished = true 
                  end
               end)
            copas.addthread(
               function()
                  local s = socket.connect('localhost',port)
                  s:settimeout(0)
                  local client = copas.wrap(s)
                  local msg = 'HALLO'
                  client:send(msg..'\n')
                  local echoed = client:receive('*l')
                  s:close()
                  assert.is_truthy(echoed == msg)
                  if other_finished then                     
                     done()
                  else
                     other_finished = true 
                  end
               end)
         end)

      it(
         'this is sync though',
         function()
            print('sync')
            assert.is_truthy(true)
            assert.is_truthy(true)
            assert.is_truthy(true)
         end)

      describe(
         'deeper context', 
         function()
                  before_each(            
                     function()
                        print('before each sync')
                     end)

                  it(
                     'sent messages are echoed correctly two times in a row',
                     async,
                     function(done)
                        print('DEEP')
                        copas.addthread(
                           function()
                              local s = socket.connect('localhost',port)
                              s:settimeout(0)
                              local client = copas.wrap(s)
                              local msg = 'HALLO'
                              client:send(msg..'\n')
                              local echoed = client:receive('*l')
                              assert.is_truthy(echoed == msg)
                              msg = 'HALLO again'
                              client:send(msg..'\n')
                              local echoed = client:receive('*l')
                              s:close()
                              assert.is_truthy(echoed == msg)
                              print('F DEEP')
                              done()
                           end)
                     end)
         end)
   end)

return 'copas'