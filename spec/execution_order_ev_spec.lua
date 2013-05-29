if not pcall(require, "ev") then
  describe("Testing ev test order", function()
    pending("The 'ev' loop test order was not tested because 'ev' isn't installed")
  end)
else

  local ev = require'ev'
  local loop = ev.Loop.default

  local eps = 0.000000000001

  local egg = ''

  local concat = function(letter)
    local yield = function(done)
      ev.Timer.new(
        async(function()
          egg = egg..letter
          done()
        end),eps):start(loop)
    end
    return yield
  end

  setloop('ev')

  describe('before_each after_each egg test', function()
    setup(concat('S'))

    teardown(concat('T'))

    before_each(concat('b'))

    after_each(concat('a'))

    describe('asd', function()
      before_each(concat('B'))

      after_each(concat('A'))

      it('1', function()
        assert.equal(egg,'SbB')
        egg = egg..'1'
      end)

      it('2', function()
        assert.equal(egg,'SbB1AabB')
        egg = egg..'2'
      end)
    end)

    it('3', function()
      assert.equal(egg,'SbB1AabB2Aab')
      egg = egg..'3'
    end)
  end)

  it('4',function()
    assert.equal(egg,'SbB1AabB2Aab3aT')
  end)

end