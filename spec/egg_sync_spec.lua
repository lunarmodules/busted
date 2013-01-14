local egg = ''
describe(
   'before_each after_each egg test',
   function()
      before(
         function()
            egg = egg..'S'
         end)
      after(
         function()
            egg = egg..'T'
         end)
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
                  assert.equal(egg,'SbB')
               end)
            it(
               '2',
               function()
                  assert.equal(egg,'SbBAabB')
               end)
         end)
      it(
         '3',
         function()
            assert.equal(egg,'SbBAabBAab')
         end)
   end)

it(
   '4',
   function()
     assert.equal(egg,'SbBAabBAabaT')
   end)