local ev = require'ev'
local loop = ev.Loop.default
require'busted'

local eps = 0.000000000001

local egg = ''
local concat = function(letter)
   local yield = function(done)
      ev.Timer.new(
         function()
            egg = egg..letter
            done()
         end,eps):start(loop)
   end
   return yield
end

describe(
   'before_each after_each egg test',
   function()
      before_each(
         async,
         concat('b'))
                 
      after_each(
         async,
         concat('a'))

      describe(
         'asd',
         function()
            before_each(
               async,
               concat('B'))

            after_each(
               async,
               concat('A'))

            it(
               '1',
               function()
                  assert.equal(egg,'bB')
               end)
            it(
               '2',
               function()
                  assert.equal(egg,'bBAabB')
               end)
         end)
      it(
         '3',
         function()
            assert.equal(egg,'bBAabBAab')
         end)
   end)

return 'ev',loop