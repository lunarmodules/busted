local busted 
local loop = {}
local timers = {}

-- the timers implemented here will not be useful within the 
-- context of the 'default' loop (this file). But they can be used
-- in combination with coroutine schedulers, see 'busted.loop.copas.lua'
-- for an example of how the timer code here can be reused.

local checktimers = function()
  local now = busted.gettime()
  for _,t in pairs(timers) do
    if now > t.timeout then
      t.on_timeout()
      t:stop()
    end
  end
end

loop.create_timer = function(secs,on_timeout)
  busted = busted or require("busted")  -- lazy-load to prevent 'require-loop'
  local timer = {
    timeout = busted.gettime() + secs,
    on_timeout = on_timeout,
    stop = function(self)
      timers[self] = nil
    end,
  }
  timers[timer] = timer
  return timer
end

loop.step = function()
  busted = busted or require("busted")  -- lazy-load to prevent 'require-loop'
  checktimers()
end

loop.pcall = pcall

return loop
