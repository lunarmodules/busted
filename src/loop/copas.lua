local copas = require'copas'
local super = require'busted.loop.default'

-- create OO table, using `loop.default` as the ancestor/super class
return setmetatable({ 
    step = function()
      copas.step(0)
      super.step()  -- call ancestor to check for timers 
    end,
    pcall = copcall
  }, { __index = super})

