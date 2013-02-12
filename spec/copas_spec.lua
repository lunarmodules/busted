package.path = './?.lua;'..package.path
local copas = require'copas'
local socket = require'socket'

local port = 19281

local echo = function(done)
   local listener = socket.bind('*',port)
   copas.addthread(
      guard(
         function()
            local s = socket.tcp()
            s:setoption('tcp-nodelay',true)
            copas.connect(s,'localhost',port)
            local client = copas.wrap(s)
            local msg = 'HALLO'
            client:send(msg..'\n')
            assert(client:receive('*l')==msg)
            s:close()
            listener:close()
            done()
         end))
   copas.addserver(
      listener,
      guard(
         function(skt)
            while true do
               local data = copas.receive(skt)
               if not data then
                  return
               end
               copas.send(skt,data..'\n')               
            end
         end))
end

local yield = echo

setloop('copas')
busted.setup_async_tests(yield,'copas')

local statuses = busted.run{debug=true}

busted.reset()
busted.describe_statuses(statuses)

