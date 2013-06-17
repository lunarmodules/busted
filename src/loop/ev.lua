local ev = require'ev'

local loop = {}

loop.create_timer = function(secs,on_timeout)
  local timer
  timer = ev.Timer.new(function()
    timer = nil
    on_timeout()
  end,secs)
  
  timer:start(ev.Loop.default)
  return {
    stop = function()
      if timer then
        timer:stop(ev.Loop.default)
        timer = nil
      end
    end
  }
end

loop.step = function()
  ev.Loop.default:loop()
end

loop.pcall = pcall

return loop
