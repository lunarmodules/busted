-- Runs internally an ev async test and checks the returned statuses.
--
--
package.path = './?.lua;'..package.path
local ev = require'ev'
local loop = ev.Loop.default
require'busted'

local eps = 0.000000000001

local yield = function(done)
   ev.Timer.new(
      function()
         done()
      end,eps):start(loop)
end

busted.setup_async_tests(yield,'ev')

local options = {
   debug = true,
   loop = function()
      loop:loop()
   end
} 

local statuses = busted.run(options)

busted.reset()
busted.describe_statuses(statuses)
