package.path = './?.lua;'..package.path
local copas = require'copas'
local socket = require'socket'
require'busted'

local port = 19281

local echo_server = copas.addserver(
   socket.bind('*',port),
   function(skt)
      while true do
         local data = copas.receive(skt)
         if not data then
            return
         end
         copas.send(skt,data..'\n')               
      end
   end)

local echo = function(done)
   copas.addthread(
      function()
         local s = socket.connect('localhost',port)
         s:settimeout(0)
         local client = copas.wrap(s)
         local msg = 'HALLO'
         client:send(msg..'\n')
         client:receive('*l')
         s:close()
         done()
      end)
end

local yield = echo

busted.setup_async_tests(yield,'copas')

local options = {
   debug = true,
   loop = function()
      copas.step(0)
   end
} 

local statuses = busted.run(options)

busted.reset()
busted.describe_statuses(statuses)

