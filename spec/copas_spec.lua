if not pcall(require, "copas") then
  describe("Testing copas loop", function()
    pending("The 'copas' loop was not tested because 'copas' isn't installed")
  end)
else
  local generic_async = require'generic_async_test'
  local statuses = busted.run_internal_test(function()
    local copas = require'copas'
    local socket = require'socket'

    local port = 19281

    local echo = function(done)
      local listener = socket.bind('*',port)

      copas.addthread(
        async(
          function()
            local s = socket.tcp()

            s:setoption('tcp-nodelay',true)
            copas.connect(s,'localhost',port)

            local client = copas.wrap(s)
            local msg = 'HALLO'

            client:send(msg..'\n')

            assert(client:receive('*l') == msg)

            s:close()
            listener:close()
            done()
        end)
      )

      copas.addserver(
        listener,
        async(
          function(skt)
            while true do
              local data = copas.receive(skt)

              if not data then
                return
              end

              copas.send(skt,data..'\n')
            end
        end)
      )
    end

    local yield = echo

    setloop('copas')
    generic_async.setup_tests(yield,'copas')
  end)

  generic_async.describe_statuses(statuses)
end
