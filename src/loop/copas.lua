local copas = require'copas'
require'coxpcall'

local loop = {}

loop.pcall = copcall

loop.step = function()
  copas.step(0)
end

return loop
