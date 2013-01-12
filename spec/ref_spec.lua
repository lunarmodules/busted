
require'busted'

describe(
   '1 Context',
   function()
      it(
         '1 Test A',
         function()
--            assert.is_true(true)
         end)
      it(
         '1 Test B',
         function()
            assert.is_true(true)
            assert.is_true(false)
         end)
      it(
         '1 Test C',
         function()
            t.x = 4
         end)
      describe(
         '1.1 Context',
         function()
            it(
               '1.1 Test A',
               function()
                  assert.is_true(true)
               end)
         end)

   end)