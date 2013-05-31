local copas = require'copas'

local loop = {}

loop.step = function()
  copas.step(0)
end

return loop
