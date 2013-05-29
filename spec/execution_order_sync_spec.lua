local egg = ''
describe(
  'before_each after_each egg test',
  function()
    setup(
      function()
        egg = egg..'S'
      end)
    teardown(
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
            egg = egg..'1'
          end)
        it(
          '2',
          function()
            assert.equal(egg,'SbB1AabB')
            egg = egg..'2'
          end)
      end)
    it(
      '3',
      function()
        assert.equal(egg,'SbB1AabB2Aab')
        egg = egg..'3'
      end)
  end)

it(
  '4',
  function()
    assert.equal(egg,'SbB1AabB2Aab3aT')
  end)
