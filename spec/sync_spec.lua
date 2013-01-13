 -- normal / sync test
package.path = './?.lua;'..package.path
require'busted'

it(
   'sync test',
   function(done)
      assert.is_truthy(true)
   end)
