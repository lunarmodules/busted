local egg = ''
describe(
   'before_each after_each egg test',
   function()
      before_each(
         function()
            egg = egg..'b'
         end)
      after_each(
         function()
            egg = egg..'a'
         end)
      describe(
         'asd',
         function()
            before_each(
               function()
                  egg = egg..'B'
               end)
            after_each(
               function()
                  egg = egg..'A'
               end)
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