local ev = require'ev'
local loop = ev.Loop.default

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

setloop('ev')

describe('before_each after_each egg test', function()
  before(async, concat('S'))

  after(async, concat('T'))

  before_each(async, concat('b'))

  after_each(async, concat('a'))

  describe('asd', function()
    before_each(async, concat('B'))

    after_each(async, concat('A'))

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

